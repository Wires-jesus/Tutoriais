CREATE OR REPLACE PACKAGE BODY PKG_MEDICAMENTOS
/***********************************************************************************************
  Package Body de Processos Específicos do Módulo de Medicamentos
  ----------------     Historico     ------------------------------------------------------------
  Data        Responsável        Tarefa          Comentario
  27/02/2018  Anderson Silva     DDMEDICA-570    Primeira Versao
  04/11/2019  Anderson Silva     DDMEDICA-1241   RCA por Linha e Tributação de Pedido Avaria
  20/11/2019  Anderson Silva     DDMEDICA-1388   Opção para usar aba perda da tributação no pedido de avaria
  28/12/2019  Anderson Silva     DDMEDICA-1691   PMPF na Base do ST
  05/06/2020  Anderson Silva     DDMEDICA-3065   Desoneração do Recálculo do ST
  05/08/2020  Anderson Silva     DDMEDICA-3545    Não processar Comissão RCA Nula
  17/08/2020  Anderson Silva     DDMEDICA-3639   Simples Nacional ST Fonte na Integradora 
  22/12/2020  Anderson Silva     DDMEDICA-5115   Transferência de Avaria não gravar como Simples Remessa
  25/05/2020  Anderson Silva     DDMEDICA-6666   Recalculo ST Itens Bonificados inseridos pelo Brinde Express na INTEGRADORA_MED
  10/06/2021  Anderson Silva     DDMEDICA-6772   Movida para esta Package o Procedimento para Definir o Código Fiscal
  29/06/2021  Anderson Silva     DDMEDICA-6900   Procedimento para obter o Custo da Promoção de Markup
  15/09/2021  Anderson Silva     DDMEDICA-7594   Customização da Base ST com SUFRAMA/Redução PISCOFINS e DESONERACAO
  30/09/2021  Anderson Silva     DDMEDICA-7697   ST Recolhido anteriormente
  21/10/2021  Anderson Silva     DDVENDAS-31316  ST Antecipado não somar ao CMV
  27/10/2021  Anderson Silva     DDVENDAS-31441  Preencher campos de BCR com o ST Antecipado
  24/11/2021  Anderson Silva     DDVENDAS-32054  VLICMSSUBSTITUTOANTERIOR - aplicar a Aliq 2 do ST
  21/02/2022  Anderson Silva     DDVENDAS-33718  Utilizar Endereço Entrega
  22/03/2022  Anderson Silva     DDVENDAS-34479  PMPF podendo ser recebido por embalagem
  19/04/2022  Anderson Silva     DDVENDAS-35050  Ajuste para melhorar as dependências centralizando alguns procedimentos nesta Package
  24/04/2022  Anderson Silva     DDVENDAS-35125  Melhoria Referências Externas
  04/05/2022  Anderson Silva     DDVENDAS-35253  Limitar ST FECP a Clientes com ST Fonte
  02/06/2022  Anderson Silva     DDVENDAS-35830  Exceções ABCFARMA/CMED
  15/08/2022  Anderson Silva     DDVENDAS-37241  Cálculo da Desoneração somente no Faturamento
  28/09/2022  Anderson Silva     DDVENDAS-38075 - PMC não entra nas Exceções CMED
  30/12/2022  Anderson Silva     DDVENDAS-39621 - Ajuste chamada ST 4.0
  28/02/2023  Anderson Silva     DDVENDAS-40446 - Performance cálculo Função PIS_COFINS_ICMS
  27/04/2023  Anderson Silva     DDVENDAS-41753 - Inclusão de prioriadade de exceção do Convênio Isenção ICMS
  14/02/2024  Anderson Silva     DDVENDAS-46088 - Filial Retira por Cliente Filial e UF Cliente
 ************************************************************************************************/
IS PRAGMA SERIALLY_REUSABLE;

 /*****************************************
  DDMEDICA-4225 - Controle de Versionamento
  -----------------------------------------
  Issue                 Versão
  DDMEDICA-6666         v@30.3.1
  DDMEDICA-6772         v@30.4.1
  DDMEDICA-7584         v@30.4.2
  DDVENDAS-33718        v@31.1.1
  DDVENDAS-35050        v@31.1.2
  DDVENDAS-35125        v@31.1.3
  DDVENDAS-35253        v@31.1.4
  DDVENDAS-35830        v@31.1.5
  DDVENDAS-37241        v@31.1.6
  DDVENDAS-38075        v@31.1.7
  DDVENDAS-39621        v@33.1.1
  DDVENDAS-40446        v@33.1.9
  DDVENDAS-41753        v@32.1.10
  DDVENDAS-46088        v@35.0.1
  *****************************************/
  FUNCTION F_OBTER_VERSIONAMENTO RETURN VARCHAR2 IS
    vvVersao VARCHAR2(10);
  BEGIN
  
    -->> *** A CADA ALTERAÇÃO INCREMENTAR AQUI A VERSÃO ***
    vvVersao := 'v@35.0.1';
  
    RETURN 'MED_' || vvVersao;
    
  END F_OBTER_VERSIONAMENTO;

  ------------------------------------------------------------------------------
  -- Função para Verificar se Usa Regra Específica de Medicamentos --
  -------------------------------------------------------------------
  FUNCTION FUSA_REGRA_MEDICAMENTOS(pi_vCodFilial IN VARCHAR2,
                                   pi_vNome      IN VARCHAR2)
  RETURN VARCHAR2 IS
    vvRetUsaRegraMedicamentos VARCHAR2(240);
  BEGIN
    -- Verifica se usa regra
    BEGIN
      EXECUTE IMMEDIATE ' SELECT VALOR FROM PCREGRASEXCECAOMED WHERE NOME = ' || '''' || pi_vNome || '''' || ' AND CODFILIAL = ' || '''' || pi_vCodFilial || ''''
                   INTO vvRetUsaRegraMedicamentos;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vvRetUsaRegraMedicamentos := 'N';
      WHEN OTHERS THEN
        vvRetUsaRegraMedicamentos := 'N';
    END;
    -- Retorno
    RETURN vvRetUsaRegraMedicamentos;
  END FUSA_REGRA_MEDICAMENTOS;

  -- DDVENDAS-33718
  procedure proc_pcparamfilial(p_codfilial in pcfilial.codigo%type,
                               p_nome      in pcparamfilial.nome%type,
                               p_padrao    in pcparamfilial.valor%type,
                               p_valor     out pcparamfilial.valor%type) is
  
    vsnome pcparamfilial.nome%type;
  
  begin
  
    vsnome := upper(trim(p_nome));
  
    begin
      select nvl(p.valor, p_padrao)
        into p_valor
        from pcparamfilial p
       where upper(trim(p.nome)) = vsnome
         and p.codfilial = p_codfilial;
    exception
    
      when no_Data_found then
      
        BEGIN
        
          select nvl(p.valor, p_padrao)
            into p_valor
            from pcparamfilial p
           where upper(trim(p.nome)) = vsnome
             and p.codfilial = '99';
        exception
          when no_data_found then
          
            p_valor := p_padrao;
          
        end;
      
      when others then
        p_valor := p_padrao;
      
    end;
  
  end proc_pcparamfilial;

  FUNCTION F_BUSCARPARAMETRO_ALFA(PNOMEPARAM   IN VARCHAR2,
                                  PCODFILIAL   IN VARCHAR2,
                                  PVALORSENULO IN VARCHAR2)
   RETURN VARCHAR2
  IS
  vsVALORTEMP  VARCHAR2(100);
  BEGIN

    SELECT NVL(VALOR, PVALORSENULO)
      INTO vsVALORTEMP
      FROM PCPARAMFILIAL
     WHERE NOME = PNOMEPARAM
       AND CODFILIAL = PCODFILIAL;

    RETURN vsVALORTEMP;

  EXCEPTION
   WHEN OTHERS THEN

     RETURN PVALORSENULO;

  END F_BUSCARPARAMETRO_ALFA;

  FUNCTION F_BUSCARPARAMETRO_NUM(PNOMEPARAM   IN VARCHAR2,
                                 PCODFILIAL   IN VARCHAR2,
                                 PVALORSENULO IN NUMBER)
   RETURN NUMBER
  IS
  vnVALORTEMP  NUMBER;
  BEGIN

    SELECT NVL(TO_NUMBER(VALOR), PVALORSENULO)
      INTO vnVALORTEMP
      FROM PCPARAMFILIAL
     WHERE NOME = PNOMEPARAM
       AND CODFILIAL = PCODFILIAL;

    RETURN vnVALORTEMP;

  EXCEPTION
    WHEN INVALID_NUMBER THEN

    BEGIN
      SELECT NVL(TO_NUMBER(translate(VALOR,',.','.,')), PVALORSENULO)
        INTO vnVALORTEMP
        FROM PCPARAMFILIAL
       WHERE NOME = PNOMEPARAM
         AND CODFILIAL = PCODFILIAL;

      RETURN vnVALORTEMP;

    EXCEPTION
      WHEN INVALID_NUMBER THEN
        RAISE_APPLICATION_ERROR(-20000, 'NÚMERO INVÁLIDO ATRIBUÍDO AO PARÂMETRO: "' || PNOMEPARAM || '". VERIFIQUE O SEPARADOR DECIMAL');
    WHEN OTHERS THEN
      RETURN PVALORSENULO;
    END;

    WHEN OTHERS THEN

      RETURN PVALORSENULO;

  END F_BUSCARPARAMETRO_NUM;
  
 /***********************************************************************************************
  FUNÇÃO...: FFORMATAR_NUMERO_TEXTO_SQL
  DESCRIÇÃO: Função para Formatar um Número para Texto SQL (manter o ponto como separado de casas)
  ***********************************************************************************************/
  FUNCTION FFORMATAR_NUMERO_TEXTO_SQL(pi_nNumero IN NUMBER) RETURN VARCHAR2 IS
    vvTextoRetorno  VARCHAR2(200);
  BEGIN

    -- Prepara Texto Retorno
    vvTextoRetorno := TO_CHAR(pi_nNumero);

    -- Troca Virgulas por ponto
    vvTextoRetorno := REPLACE(vvTextoRetorno,',','.');

    -- Elimina espaços em branco
    vvTextoRetorno := TRIM(vvTextoRetorno);

    -- Retorno
    RETURN vvTextoRetorno;

  END FFORMATAR_NUMERO_TEXTO_SQL;

  /*******************************************************************************
   Nome         : definircodfiscalpcmov
   Descricão    : Procedimento para definir o Código Fiscal da PCMOV
  ********************************************************************************/
  PROCEDURE definircodfiscalpcmov(vscalculast                    IN pcclient.calculast%TYPE,
                                  vsconfaz                       IN pcprodut.confaz%TYPE,
                                  vniva                          IN pcpedi.iva%TYPE,
                                  vnpauta                        IN pcpedi.pauta%TYPE,
                                  vsclientefontest               IN pcclient.clientefontest%TYPE,
                                  vnivafonte                     IN pctribut.ivafonte%TYPE,
                                  vnaliqicms1fonte               IN pctribut.aliqicms1fonte%TYPE,
                                  vnaliqicms2fonte               IN pctribut.aliqicms2fonte%TYPE,
                                  vncfoisentost                  IN NUMBER,
                                  vncfoisentostinter             IN NUMBER,
                                  vncfoisentostinternasc         IN NUMBER,
                                  vssittributisentost            IN pctribut.sittributisentost%TYPE,
                                  vbpessoafisica                 IN BOOLEAN,
                                  pncondvenda                    IN pcpedc.condvenda%TYPE,
                                  vncfoestpf                     IN NUMBER,
                                  vncfointerpf                   IN NUMBER,
                                  vncfointernascpf               IN NUMBER,
                                  vssittributpf                  IN pctribut.sittributpf%TYPE,
                                  vc2codigosuframa               IN pcclient.sulframa%TYPE,
                                  pnvldescsuframa                IN pcpedi.vldescsuframa%TYPE,
                                  vsindustria                    IN pcfilial.industria%TYPE,
                                  pnnumnotaconsig                IN pcpedc.numnotaconsig%TYPE,
                                  vncfomercadoriaconsig          IN NUMBER,
                                  vncfomercadoriaconsiginter     IN NUMBER,
                                  vncfomercadoriaconsiginternasc IN NUMBER,
                                  vncfobonific                   IN NUMBER,
                                  vncfobonificinter              IN NUMBER,
                                  vncfobonificinternasc          IN NUMBER,
                                  vncfovendaentfut               IN NUMBER,
                                  vncfovendaentfutinter          IN NUMBER,
                                  vncfosimpentfut                IN NUMBER,
                                  vncfosimpentfutinter           IN NUMBER,
                                  vncfotransf                    IN NUMBER,
                                  vncfotransfinter               IN NUMBER,
                                  vncfotransfinternasc           IN NUMBER,
                                  vncodfiscaltroca               IN NUMBER,
                                  vncodfiscaltrocainter          IN NUMBER,
                                  vncodfiscaltrocainternasc      IN NUMBER,
                                  vncfoprontaent                 IN NUMBER,
                                  vncfoprontaentinter            IN NUMBER,
                                  vncfoprontaentinternasc        IN NUMBER,
                                  vncfovendaprontaent            IN NUMBER,
                                  vncfovendaprontaentinter       IN NUMBER,
                                  vncfovendaconsig               IN NUMBER,
                                  vncfovendaconsiginter          IN NUMBER,
                                  vncfovendaconsiginternasc      IN NUMBER,
                                  psserieecf                     IN pcpedc.serieecf%TYPE,
                                  pstipocfoptv4                  IN pcpedc.tipocfoptv4%TYPE,
                                  pscodcob                       IN pcpedc.codcob%TYPE,
                                  pnpvenda                       IN pcpedi.pvenda%TYPE,
                                  pstipoempresa                  IN pcclient.tipoempresa%TYPE,
                                  pssittributnrpa                IN pctribut.sittributnrpa%TYPE,
                                  psprontaentrega                IN pcpedc.prontaentrega%TYPE,
                                  psusacfopvendanatv10           IN pcpedc.usacfopvendanatv10%TYPE,
                                  pncodfiscaltv9                 IN pctribut.codfiscaltv9%TYPE,
                                  pncodfiscalintertv9            IN pctribut.codfiscalintertv9%TYPE,
                                  pncodfiscalinternasctv9        IN pctribut.codfiscalinternasctv9%TYPE,
                                  pscompraconsignado             IN pcprodut.compraconsignado%TYPE,
                                  pncodfiscalconsig              IN pctribut.codfiscalconsig%TYPE,
                                  pncodfiscalconsiginter         IN pctribut.codfiscalconsiginter%TYPE,
                                  pncodfiscalconsiginternac      IN pctribut.codfiscalconsiginternac%TYPE,
                                  psvendatriangular              IN pcpedc.vendatriangular%TYPE,
                                  pncodfiscaltriangular          IN pctribut.codfiscaltriangular%TYPE,
                                  pncodfiscaltriangularinter     IN pctribut.codfiscaltriangularinter%TYPE,
                                  pncodfiscaltriangularinternasc IN pctribut.codfiscaltriangularinternasc%TYPE,
                                  pncfoptriangularpf             IN pctribut.codfiscaltriangularpf%TYPE,
                                  pncfoptriangularinterpf        IN pctribut.codfiscaltriangularinterpf%TYPE,
                                  pncfoptriangularinternascpf    IN pctribut.codfiscaltriangularinternascpf%TYPE,
                                  vncfopcontaordem               IN pctribut.codfiscalcontaordem%TYPE,
                                  vncfopcontaordeminter          IN pctribut.codfiscalcontaordeminter%TYPE,
                                  vncfopcontaordemsimpent        IN pctribut.codfiscalcontaordemsimpent%TYPE,
                                  vncfopcontaordemsimpentinte    IN pctribut.codfiscalcontaordemsimpentinte%TYPE,
                                  vscontaordem_pedc              IN pcpedc.contaordem%TYPE,
                                  vncfoest                       IN OUT PCMOVPREFAT.codfiscal%TYPE,
                                  vncfointer                     IN OUT PCMOVPREFAT.codfiscal%TYPE,
                                  vncfointernasc                 IN OUT PCMOVPREFAT.codfiscal%TYPE,
                                  vssittribut                    IN OUT PCMOVPREFAT.sittribut%TYPE,
                                  vsusacfopbnfparabrinde         IN OUT pctribut.usacfopbnfparabrinde%TYPE,
                                  pncodbnf                       IN pcpedc.codbnf%TYPE,
                                  pssittributtv7                 IN OUT pctribut.sittributtv7%TYPE,
                                  psfornecentrega                IN pcpedc.fornecentrega%TYPE,
                                  psbonific                      IN pcpedi.bonific%TYPE,
                                  pssittributbonific             IN pctribut.sittributbonific%TYPE,
                                  psisentaicmsbonific            IN pctribut.isentaicmsbonific%TYPE,
                                  psSITTRIBUTBNFTV1              IN PCTRIBUT.SITTRIBUTBNFTV1%TYPE, --HIS.01758.2014
                                  psItemTV1Bnf                   IN VARCHAR2, -- HIS.00178.2015
                                  vsregimeespisenstfonte         IN PCMOVCOMPLEPREFAT.REGIMEESPISENSTFONTE%TYPE,
                                  --HIS.01079.2015
                                  psTipoCliMed                   IN VARCHAR2,
                                  psUtilizaNatOpSRTV20           IN VARCHAR2,
                                  vncfopsrest                    IN PCTRIBUT.CODFISCALSRESTSR%TYPE,
                                  vncfopsrinter                  IN PCTRIBUT.CODFISCALSRINTE%TYPE,
                                  vncfopsrexter                  IN pctribut.CODFISCALSREXT%TYPE,
                                  pnnumtransentorigconsig        in NUMBER default 0,
                                  pssittributorgaopub            IN PCTRIBUT.SITTRIBUTORGAOPUB%TYPE,   -- 4262.058352.2016
                                  psorgaopubestadual             IN PCCLIENT.ORGAOPUB%TYPE,            -- 4262.058352.2016
                                  psorgaopubmunicipal            IN PCCLIENT.Orgaopubmunicipal%TYPE,   -- 4262.058352.2016
                                  psorgaopubfederal              IN PCCLIENT.ORGAOPUBFEDERAL%TYPE,     -- 4262.058352.2016
                                  vncodicmsimplesnac             IN PCTRIBUT.CODICMSIMPLESNAC%TYPE,    --HIS.00875.2013 --ICMS_SN
                                  vssittribsimplesnac            IN PCTRIBUT.SITTRIBUTSIMPLESNAC%TYPE, --HIS.00875.2013 --ICMS_SN
                                  pi_nNumPed                     IN NUMBER, -- 2350.117434.2016 -->> v26-v27_161024
                                  pi_nCarregamento               IN NUMBER, -- 2350.117434.2016 -->> v26-v27_161024
                                  pi_nNumTransVenda              IN NUMBER,  -- 2350.117434.2016 -->> v26-v27_161024
                                  po_vTipoCodFiscal              OUT VARCHAR2, -- HIS.03261.2016
                                  po_vTipoSitTrib                OUT VARCHAR2, -- HIS.03261.2016
                                  po_vLogProcMed                 OUT VARCHAR2 -- DDMEDICA-6772
                                  )
  /******************************************************************************************
    ->Nome da PROCEDURE : DEFINIR_CODFISCALPCMOV
    ->Objetivo          : Retornar o PCMOVPREFAT.CODFISCAL para o Item da NF (PCMOVPREFAT.CODFISCAL)
    ->Versao            : Pacote
    ->Utilização        : FATU_FATURA_PEDIDO

    -------------------------------- Historico ------------------------------------------------
    Data         Responsavel    Tarefa    Comentarios
    -----------  ------------------- Historico ------------------------------------------------
    20/03/2007   Pablo                    Procedure criada visando corrigir erro Procedure too Large
                                          ao compilar a procedure de faturamento FATU_FATURA_PEDIDO
                                          no Oracle 8i
    26/03/2007   Pablo          40720     Alteração para validar o PCCLIENT.TIPOEMPRESA 'NRPA' nessa situação
                                          SitTribut := SitTributNRP
    12/04/2007   Pablo          41641     Caso a venda seja Pronta Entrega (PCPEDC.PRONTAENTREGA = 'S') e TV4
                                          o Código Fiscal será o mesmo da Venda Manifesto (TV13), processo ref.
                                          a rotina 1444.
    17/05/2007   Pablo          44116     Alterado o processo da tarefa 41641, caso a venda TV4 e (PCPEDC.PRONTAENTREGA = 'S')
                                          será retornado o Codigo Fiscal da venda TV14
    26/01/2008   Sabrina        57253     Alterada a forma de validacao do st fonte, ja que para clientes
                                          no regime do SuperSimples IvaFonte = 0
    08/04/2008   Pablo          60990     Alteração para definir o Código Fiscal do Item como Bonificação caso a venda seja TV14
                                          com Cobrança igual 'BNF'.
    02/05/2008   Pablo          60930     Alteração para validar o CFOP do item brinde conforme o novo parâmetro PCTRIBUT.UsaCFOPBNFParaBrinde
                                          caso o mesmo seja igual 'N' será utilizado o mesmo CFOP da venda.
    14/07/2008   Pablo\Diego    64486     Caso seja TV10 e o novo campo (PCPedC.UsaCFOPVendaNaTV10 = 'S') será utilizando o CFOP de Venda.
    22/05/2009   Pablo          81651     Alteração para retornar o Codigo Fiscal para TV9 conf. novos campos PCTribut.CodFiscalTv9, PCTribut.CodFiscalInterTv9,
                                          PCTribut.CodFiscalInternascTv9 caso os campos seja nulo será retornardo apartir do CFOP de BNF.
    18/10/2010   Pablo         118301     Alteração para validar o CFOP de Venda Triangular para PF e não considerar venda TV20 como triangular
    16/06/2010   Thiago Melo   134475     Implementado a validação do campo pctribut.sittributtv7.
    17/06/2010   Thiago Melo   134475     Erros homologação Fernandes.
    -----------------------------------------------------------------------------------------*/
   IS
    -- HIS.01562.2015
    vncfoestOriginal               pctribut.codfiscal%TYPE;
    vncfointerOriginal             pctribut.codfiscalinter%TYPE;
    vncfointernascOriginal         pctribut.codfiscalinternasc%TYPE;
    --
  BEGIN
    -- Guarda o CFOP Original de Venda - HIS.01562.2015
    vncfoestOriginal       := vncfoestpf;
    vncfointerOriginal     := vncfointerpf;
    vncfointernascOriginal := vncfoisentostinternasc;

    -- MED-1022 - Somente se o Cliente não for ST Fonte valida CFOP de Isento ST
    IF (NVL(vsclientefontest,'N') <> 'S') THEN
      -- Tarefa 27661
      IF ((vscalculast = 'N') --ST NORMAL
         AND (vsconfaz = 'N') AND ((vniva > 0) OR (vnpauta > 0))) OR
         ((vsclientefontest = 'N') -- ST FONTE
         --AND (vnivafonte > 0) ) -- Tarefa 57253: alterada checagem de incidencia de st fonte
         AND (vniva = 0) AND
         ((vnaliqicms1fonte > 0) OR (vnaliqicms1fonte > 0))) THEN
        vncfoest       := vncfoisentost;
        vncfointer     := vncfoisentostinter;
        vncfointernasc := vncfoisentostinternasc;
        vssittribut    := vssittributisentost;
        -- HIS.03261.2016
        po_vTipoCodFiscal := 'vncfoisentost > ' || vncfoest;
        po_vTipoSitTrib   := 'vssittributisentost > ' || vssittribut;
      END IF;
    END IF;

    -- Se for Venda p/ Pessoa Fisica
    -- Nao atribuir o codigo fiscal de pessoa fisica quando a venda
    -- for Bonificacao - Data: 29/12/2003
    IF (vbpessoafisica AND (pncondvenda NOT IN (5, 9, 11, 20)) AND (NVL(psbonific,'N') NOT IN ('S','F'))) THEN
      vncfoest       := vncfoestpf;
      vncfointer     := vncfointerpf;
      vncfointernasc := vncfointernascpf;
      vssittribut    := vssittributpf;
      -- HIS.03261.2016
      po_vTipoCodFiscal := 'vncfoestpf > ' || vncfoest;
      po_vTipoSitTrib   := 'vssittributpf > ' || vssittribut;
      -- Guarda o CFOP Original de Venda - PF - HIS.01562.2015
      vncfoestOriginal       := vncfoestpf;
      vncfointerOriginal     := vncfointerpf;
      vncfointernascOriginal := vncfoisentostinternasc;
    END IF;

    IF UPPER(TRIM(pstipoempresa)) = 'NRPA' THEN
      vssittribut := pssittributnrpa;
    END IF;

    -- Se for venda suframada
    IF (vc2codigosuframa IS NOT NULL) AND (NVL(pnvldescsuframa, 0) > 0) THEN
      vncfoest       := 5110;
      vncfointer     := 6110;
      vncfointernasc := 7110;
      -- HIS.03261.2016
      po_vTipoCodFiscal := 'suframa > ' || vncfoest;

      IF vsindustria = 'S' THEN
        vncfoest       := 5109;
        vncfointer     := 6109;
        vncfointernasc := 7109;
        -- HIS.03261.2016
        po_vTipoCodFiscal := 'suframa industria > ' || vncfoest;
      END IF;
    END IF;

    -- Venda Consignada enviada anteriormente --
    --IF pnnumnotaconsig IS NOT NULL THEN
    IF pnnumnotaconsig > 0 THEN -- HIS.03261.2016
      vncfoest       := vncfomercadoriaconsig;
      vncfointer     := vncfomercadoriaconsiginter;
      vncfointernasc := vncfomercadoriaconsiginternasc;
      -- HIS.03261.2016
      po_vTipoCodFiscal := 'pnnumnotaconsig > ' || vncfoest;
    END IF;

    -- Se for Venda Entrega Futura --
    IF pncondvenda = 7 THEN
      vncfoest   := vncfovendaentfut;
      vncfointer := vncfovendaentfutinter;
      -- HIS.03261.2016
      po_vTipoCodFiscal := 'pncondvenda = 7 > ' || vncfoest;

      IF vscontaordem_pedc = 'S' THEN
        vncfoest   := vncfopcontaordem;
        vncfointer := vncfopcontaordeminter;
        -- HIS.03261.2016
        po_vTipoCodFiscal := 'pncondvenda = 7 vscontaordem_pedc = S > ' || vncfoest;
      END IF;

      --Tarefa 134475
      if (pssittributtv7 is not null) and
         (NVL(vscontaordem_pedc, 'X') <> 'S') then
        vssittribut := pssittributtv7;
        -- HIS.03261.2016
        po_vTipoSitTrib   := 'pssittributtv7 > ' || vssittribut;
      end if;
    END IF;

    -- Se for Simples Entrega Futura --
    IF pncondvenda = 8 THEN
      vncfoest   := vncfosimpentfut;
      vncfointer := vncfosimpentfutinter;
      -- HIS.03261.2016
      po_vTipoCodFiscal := 'pncondvenda = 8 > ' || vncfoest;

      IF vscontaordem_pedc = 'S' THEN
        vncfoest   := vncfopcontaordemsimpent;
        vncfointer := vncfopcontaordemsimpentinte;
        -- HIS.03261.2016
        po_vTipoCodFiscal := 'pncondvenda = 8 vscontaordem_pedc = S > ' || vncfoest;
      END IF;
    END IF;

    -- Tarefa 81651
    IF pncondvenda = 9 THEN
      vncfoest       := pncodfiscaltv9;
      vncfointer     := pncodfiscalintertv9;
      vncfointernasc := pncodfiscalinternasctv9;
      -- HIS.03261.2016
      po_vTipoCodFiscal := 'pncondvenda = 9 > ' || vncfoest;
    END IF;

    -- Fim tarefa 81651

    -- Se for Venda Transferencia --
    IF (pncondvenda = 10) AND (psusacfopvendanatv10 = 'N') -- Tarefa 64486
     THEN
      vncfoest       := vncfotransf;
      vncfointer     := vncfotransfinter;
      vncfointernasc := vncfotransfinternasc;
      -- HIS.03261.2016
      po_vTipoCodFiscal := 'pncondvenda = 10 psusacfopvendanatv10 = N > ' || vncfoest;
    END IF;

    -- Se troca
    IF pncondvenda = 11 THEN
      vncfoest       := vncodfiscaltroca;
      vncfointer     := vncodfiscaltrocainter;
      vncfointernasc := vncodfiscaltrocainternasc;
      -- HIS.03261.2016
      po_vTipoCodFiscal := 'pncondvenda = 11 > ' || vncfoest;
    END IF;

    -- Se for Manifesto --
    IF (pncondvenda = 13) THEN
      vncfoest       := vncfoprontaent;
      vncfointer     := vncfoprontaentinter;
      vncfointernasc := vncfoprontaentinternasc;
      -- HIS.03261.2016
      po_vTipoCodFiscal := 'pncondvenda = 13 > ' || vncfoest;
    END IF;

    -- Se for Venda de Manifesto --
    IF (pncondvenda = 14) OR
       ((pncondvenda = 4) AND (psprontaentrega = 'S')) THEN
      IF (vncfovendaprontaent IS NOT NULL) AND
         (vncfovendaprontaentinter IS NOT NULL) THEN
        vncfoest   := vncfovendaprontaent;
        vncfointer := vncfovendaprontaentinter;
        -- HIS.03261.2016
        po_vTipoCodFiscal := 'Venda de Manifesto > ' || vncfoest;
      END IF;
    END IF;

    -- Tarefa 104048 (Projeto 88516 - Venda Triangular)
    IF (psvendatriangular = 'S') AND (pncondvenda <> 20) THEN
      IF NOT vbpessoafisica THEN
        vncfoest       := pncodfiscaltriangular;
        vncfointer     := pncodfiscaltriangularinter;
        vncfointernasc := pncodfiscaltriangularinternasc;
        -- HIS.03261.2016
        po_vTipoCodFiscal := 'Venda Triangular juridica > ' || vncfoest;
      ELSE
        vncfoest       := pncfoptriangularpf;
        vncfointer     := pncfoptriangularinterpf;
        vncfointernasc := pncfoptriangularinternascpf;
        -- HIS.03261.2016
        po_vTipoCodFiscal := 'Venda Triangular fisica > ' || vncfoest;
      END IF;
    END IF;

    -- 2350.113695.2015 - Ignorar CompraConsignado
    -- (Projeto 80066 - Entrada Consignada de Mercadorias) Tarefa 88714
    -- 2350.117434.2016 Compra Consignado na Venda sem Devolução Simbólica (Voltar Regra) -->> v26-v27_161024
    IF pscompraconsignado = 'S' THEN
      -->> v26-v27_161024
      IF ((pncondvenda = 1) AND -- 2350.117434.2016
          (NVL(pnnumtransentorigconsig,0) = 0)) THEN -- 2350.117434.2016
        IF pncodfiscalconsig IS NOT NULL THEN
          vncfoest := pncodfiscalconsig;
        END IF;

        IF pncodfiscalconsiginter IS NOT NULL THEN
          vncfointer := pncodfiscalconsiginter;
        END IF;

        IF pncodfiscalconsiginternac IS NOT NULL THEN
          vncfointernasc := pncodfiscalconsiginternac;
        END IF;

        -- HIS.03261.2016
        po_vTipoCodFiscal := 'pscompraconsignado = S > ' || vncfoest;

        -- LOG -->> v26-v27_161024
        po_vLogProcMed := po_vLogProcMed || '| TV1 sem Dev. Simbólica CFOP compra consignado ' || vncfoest || ';' || vncfointer;
      END IF;
    END IF;

    -- Se for Venda Consignada -- TEM QUE FICAR DEPOIS DA REGRA pscompraconsignado
    IF pncondvenda = 20 THEN
      -- HIS.01079.2015
      IF ((NVL(psTipoCliMed,' ') = 'H') AND (NVL(psUtilizaNatOpSRTV20,'N') = 'S')) THEN
        vncfoest       := vncfopsrest;
        vncfointer     := vncfopsrinter;
        vncfointernasc := vncfopsrexter;

        -- HIS.03261.2016
        po_vTipoCodFiscal := 'TV20 CFOP Hospital > ' || vncfoest;

        -- LOG -->> v26-v27_161024
        po_vLogProcMed := po_vLogProcMed || '| TV20 CFOP Hospital ' || vncfoest || ';' || vncfointer;
      ELSE
        vncfoest       := vncfovendaconsig;
        vncfointer     := vncfovendaconsiginter;
        vncfointernasc := vncfovendaconsiginternasc;

        -- HIS.03261.2016
        po_vTipoCodFiscal := 'TV20 CFOP Consignado > ' || vncfoest;

        -- LOG -->> v26-v27_161024
        po_vLogProcMed := po_vLogProcMed || '| TV20 CFOP Consignado ' || vncfoest || ';' || vncfointer;
      END IF;
    END IF;

    -- Se for Cupom Fiscal --
    IF (TRIM(UPPER(psserieecf)) = 'X') AND (pncondvenda = 4) AND
       (pstipocfoptv4 = 'OS') THEN
      vncfoest   := 5929;
      vncfointer := 6929;

      -- HIS.03261.2016
      po_vTipoCodFiscal := 'Cupom Fiscal > ' || vncfoest;
    END IF;

    -- Tarefa 29833
    IF (pncondvenda IN (4, 14)) AND -- Tarefa 60990
       ((SUBSTR(pscodcob, 1, 3) = 'BNF') OR (pscodcob = 'BNTR')) THEN
      vncfoest       := vncfobonific;
      vncfointer     := vncfobonificinter;
      vncfointernasc := vncfobonificinternasc;

      -- HIS.03261.2016
      po_vTipoCodFiscal := 'pncondvenda 4, 14 BNF > ' || vncfoest;
    END IF;

    -- Tarefa 30382
    IF pnpvenda = 0 -- Brinde
     THEN
      IF vsusacfopbnfparabrinde = 'S' -- Tarefa 60930
       THEN
        vncfoest       := vncfobonific;
        vncfointer     := vncfobonificinter;
        vncfointernasc := vncfobonificinternasc;
        -- HIS.03261.2016
        po_vTipoCodFiscal := 'vsusacfopbnfparabrinde = S > ' || vncfoest;
      END IF;
    END IF;

    --Tarefa 133549
    /*Projeto 125838 Processo de Venda Triangular com Entrega pelo Fornecedor */
    if psfornecentrega = 'S' then
      vncfoest   := 5120;
      vncfointer := 6120;
      -- HIS.03261.2016
      po_vTipoCodFiscal := 'psfornecentrega = S > ' || vncfoest;
    end if;

    --MERGE: ICMS_SN
    --HIS.00875.2013 LUCAS LIMA 08/04/2014 ------------------
    IF (UPPER(TRIM(pstipoempresa)) = 'SN')            AND
       vncodicmsimplesnac     IS NOT NULL             AND
       vssittribsimplesnac    IS NOT NULL
    THEN
       vssittribut := vssittribsimplesnac;
       -- HIS.03261.2016
       po_vTipoCodFiscal := 'vssittribsimplesnac > ' || vncfoest;
       po_vTipoSitTrib   := 'vssittribsimplesnac > ' || vssittribut;
    END IF;
    --FIM HIS.00875.2013 ------------------------------------

    -- Se for Venda do TV20 (Devolução Simbólica) -- HIS.01562.2015
    IF ((pncondvenda = 1) AND
        (NVL(pnnumtransentorigconsig,0) > 0)) THEN
      -- HIS.01079.2015
      IF ((NVL(psTipoCliMed,' ') = 'H') AND (NVL(psUtilizaNatOpSRTV20,'N') = 'S')) THEN
        vncfoest       := vncfoestOriginal;
        vncfointer     := vncfointerOriginal;
        vncfointernasc := vncfointernascOriginal;

        -- HIS.03261.2016
        po_vTipoCodFiscal := 'TV1 Dev. Simbólica CFOP Hospital > ' || vncfoest;

        -- LOG -->> v26-v27_161024
        po_vLogProcMed := po_vLogProcMed || '| TV1 Dev. Simbólica CFOP Hospital ' || vncfoest || ';' || vncfointer;
      END IF;
    END IF;

    -- 4262.058352.2016 - CST - Clientes orgão públicos municipal, estadual e federal
    IF (((psorgaopubestadual  = 'S') OR
         (psorgaopubmunicipal = 'S') OR
         (psorgaopubfederal   = 'S')) AND (pssittributorgaopub is not null)) THEN
      vssittribut := pssittributorgaopub;
      -- HIS.03261.2016
      po_vTipoSitTrib   := 'CST - Clientes orgão públicos > ' || vssittribut;
    END IF;

    -- Regime especial Isenção ST Fonte
    IF (NVL(vsregimeespisenstfonte,'N') = 'S') THEN
      vncfoest       := vncfoisentost;
      vncfointer     := vncfoisentostinter;
      vncfointernasc := vncfoisentostinternasc;
      vssittribut    := vssittributisentost;
      -- HIS.03261.2016
      po_vTipoCodFiscal := 'vsregimeespisenstfonte = S > ' || vncfoest;
      po_vTipoSitTrib   := 'vsregimeespisenstfonte = S > ' || vssittribut;
    END IF;

    -- 3378.099712.2017 - BONIFICAÇÃO VALIDAR NO FINAL --
    -----------------------------------------------------

    /* Tarefa 131448 - Erro homologação Fernandes
    -- Se for Venda Bonificada --
    IF pncondvenda IN (5)
    THEN
       vncfoest := vncfobonific;
       vncfointer := vncfobonificinter;
       vncfointernasc := vncfobonificinternasc;
    END IF;
    */
    IF pncondvenda IN (5) THEN
      IF pncodbnf = 5 THEN
        vncfoest       := vncodfiscaltroca;
        vncfointer     := vncodfiscaltrocainter;
        vncfointernasc := vncodfiscaltrocainternasc;
        -- HIS.03261.2016
        po_vTipoCodFiscal := 'pncondvenda = 5 pncodbnf = 5 > ' || vncfoest;
      ELSE
        vncfoest       := vncfobonific;
        vncfointer     := vncfobonificinter;
        vncfointernasc := vncfobonificinternasc;
        -- HIS.03261.2016
        po_vTipoCodFiscal := 'pncondvenda = 5 > ' || vncfoest;
      END IF;
      -- HIS.00799.2014
      IF (psisentaicmsbonific = 'S')
       AND (nvl(pssittributbonific,'0') <> '0') THEN
        vssittribut := pssittributbonific;
        -- HIS.03261.2016
        po_vTipoSitTrib := 'psisentaicmsbonific = S > ' || vssittribut;
      END IF;
    END IF;

    if psbonific in ('F','S') then
      vncfoest    := vncfobonific;
      vncfointer  := vncfobonificinter;
      vssittribut := psSITTRIBUTBNFTV1;
      -- HIS.03261.2016
      po_vTipoCodFiscal := 'psbonific = S > ' || vncfoest;
    end if;

    -----------HIS.00178.2015----------
    IF (psItemTV1Bnf = 'S')
      AND (pncondvenda = 1)
    THEN
      vssittribut    := psSITTRIBUTBNFTV1;
      vncfoest       := vncfobonific;
      vncfointer     := vncfobonificinter;
      vncfointernasc := vncfobonificinternasc;
      -- HIS.03261.2016
      po_vTipoCodFiscal := 'psItemTV1Bnf = S pncondvenda = 1 > ' || vncfoest;
      po_vTipoSitTrib   := 'psItemTV1Bnf = S pncondvenda = 1 > ' || vssittribut;
    END IF;
    -----------------------------------

  END definircodfiscalpcmov;

  /*******************************************************************************
   Nome         : P_MED_DEFINIR_CODFISCAL
   Descricão    : Procedimento para definir o Código Fiscal
  ********************************************************************************/
  PROCEDURE P_DEFINIR_CODFISCAL(pi_vCodFilial             IN  VARCHAR2,
                                pi_nCodCli                IN  NUMBER,
                                pi_nCodProd               IN  NUMBER,
                                pi_nCodSt                 IN  VARCHAR2,
                                pi_nCondVenda             IN  NUMBER,
                                pi_nNumNotaConsign        IN  NUMBER,
                                pi_vTipoCfopTv4           IN  VARCHAR2,
                                pi_vCodCob                IN  VARCHAR2,
                                pi_vProntaEntrega         IN  VARCHAR2,
                                pi_vUsaCfopVendaNaTv10    IN  VARCHAR2,
                                pi_vVendaTriangular       IN  VARCHAR2,
                                pi_vContaOrdem            IN  VARCHAR2,
                                pi_nCodBnf                IN  NUMBER,
                                pi_vFornecEntrega         IN  VARCHAR2,
                                pi_nNumTransEntOrigConsig IN  NUMBER,     
                                pi_nCfopNfDegusta         IN  NUMBER,
                                pi_nVlDescSuframa         IN  NUMBER,     
                                pi_nPVenda                IN  NUMBER,
                                pi_vBonific               IN  VARCHAR2,  
                                pi_vRegimeEspIsenStFonte  IN  VARCHAR2,
                                po_nCodFiscal             OUT NUMBER,                                   
                                po_vSitTrib               OUT VARCHAR2,
                                po_vTipoCodFiscal         OUT VARCHAR2,
                                po_vTipoSitTrib           OUT VARCHAR2,
                                pi_vEstEnt                IN  VARCHAR2 DEFAULT NULL) -- DDVENDAS-33718
  IS
    
    -- Dados do Cliente
    TYPE TRecDadosCliente          IS RECORD(
         Forceclipf                PCCLIENT.Forceclipf%TYPE,
         consumidorfinal           PCCLIENT.consumidorfinal%TYPE,
         tipofj                    PCCLIENT.tipofj%TYPE,
         utilizaiesimplificada     PCCLIENT.utilizaiesimplificada%TYPE,
         ieent                     PCCLIENT.ieent%TYPE,
         tipoclimed                PCCLIENT.tipoclimed%TYPE,
         usaregimeespisenstfonte   PCCLIENT.usaregimeespisenstfonte%TYPE,
         calculast                 PCCLIENT.calculast%TYPE,
         clientefontest            PCCLIENT.clientefontest%TYPE,
         sulframa                  PCCLIENT.sulframa%TYPE,
         tipoempresa               PCCLIENT.tipoempresa%TYPE,
         orgaopub                  PCCLIENT.orgaopub%TYPE,
         orgaopubmunicipal         PCCLIENT.orgaopubmunicipal%TYPE,
         orgaopubfederal           PCCLIENT.orgaopubfederal%TYPE,
         estent                    PCCLIENT.estent%TYPE,
         contribuinte              PCCLIENT.contribuinte%TYPE);
    vrDadosCliente                 TRecDadosCliente;
    -- Dados do Produto
    TYPE TRecDadosProduto          IS RECORD(
         confaz                    PCPRODUT.confaz%TYPE,
         compraconsignado          PCPRODUT.compraconsignado%TYPE);
    vrDadosProduto                 TRecDadosProduto;
    -- Dados da Tributação
    TYPE TRecDadosTributacao       IS RECORD(
         Tributacao                PCTRIBUT%ROWTYPE);
    vrDadosTributacao              TRecDadosTributacao;
    -- Dados da Filial
    TYPE TRecDadosFilial           IS RECORD(
         industria                 PCFILIAL.industria%TYPE,
         uf                        PCFILIAL.uf%TYPE);
    vrDadosFilial                  TRecDadosFilial;
    -- Dados da PCCONSUM
    TYPE TRecDadosConsum           IS RECORD(
         consideraisentoscomopf    PCCONSUM.CONSIDERAISENTOSCOMOPF%TYPE,
         usartributacaotransftv10  PCCONSUM.USARTRIBUTACAOTRANSFTV10%TYPE);
    vrDadosConsum                  TRecDadosConsum;
    -- Parâmetro
    vDESTACARICMSDEVCONSIGDIFHOSP  PCPARAMFILIAL.VALOR%TYPE;
    vFILOPTANTESIMPLESNAC          PCPARAMFILIAL.VALOR%TYPE;
    vMEDRETIRARSTBNFESTADUAL       PCPARAMFILIAL.VALOR%TYPE;
    -- Retornos do Procedimento de CFOP
    TYPE TRecDadosRetornoCfop      IS RECORD(
         vncfoest                  PCMOVPREFAT.codfiscal%TYPE,
         vncfointer                PCMOVPREFAT.codfiscal%TYPE,
         vncfointernasc            PCMOVPREFAT.codfiscal%TYPE,
         vssittribut               PCMOVPREFAT.sittribut%TYPE,
         vsusacfopbnfparabrinde    pctribut.usacfopbnfparabrinde%TYPE,
         vssittributtv7            pctribut.sittributtv7%TYPE);
    vrDadosRetornoCfop             TRecDadosRetornoCfop;
    --
    vbpessoafisica                 BOOLEAN;
    vvItemTv1Bnf                   VARCHAR2(1);
    vvRegimeEspIsenStFonte         PCPEDI.REGIMEESPISENSTFONTE%TYPE;
    vvBonific                      PCPEDI.BONIFIC%TYPE;
    -- HIS.02113.2017 - Regra Especifica Priorizar CST Órgão Público sobre o CST de Pessoa Fisica
    vvPRIORIZACAOCSTORGAOPUBPF     VARCHAR2(200);
    -- DDMEDICA-6772
    vvLogProcMed                   VARCHAR2(2000);
  BEGIN

    -- Inicializa Retornos
    po_nCodFiscal     := NULL;
    po_vSitTrib       := NULL;
    --
    po_vTipoCodFiscal := NULL;
    po_vTipoSitTrib   := NULL;

    ----------------------------
    -- Pesquisa Regra Específica
    ----------------------------

    -- HIS.02113.2017 - Regra Especifica Priorizar CST Órgão Público sobre o CST de Pessoa Fisica
    BEGIN
      vvPRIORIZACAOCSTORGAOPUBPF := NVL(FUSA_REGRA_MEDICAMENTOS('99','PRIORIZACAOCSTORGAOPUBPF'),'N');
    EXCEPTION
      WHEN OTHERS THEN
        vvPRIORIZACAOCSTORGAOPUBPF := 'N';
    END;

    --------------------------------
    -- Pesquisa dos Dados Cadastrais
    --------------------------------

    -- Pesquisa Dados do Cliente
    BEGIN
      SELECT Forceclipf
           , consumidorfinal
           , tipofj
           , utilizaiesimplificada
           , ieent
           , tipoclimed
           , usaregimeespisenstfonte
           , calculast
           , clientefontest
           , sulframa
           , tipoempresa
           , orgaopub
           , orgaopubmunicipal
           , orgaopubfederal
           , estent
           , contribuinte
        INTO vrDadosCliente.Forceclipf
           , vrDadosCliente.consumidorfinal
           , vrDadosCliente.tipofj
           , vrDadosCliente.utilizaiesimplificada
           , vrDadosCliente.ieent
           , vrDadosCliente.tipoclimed
           , vrDadosCliente.usaregimeespisenstfonte
           , vrDadosCliente.calculast
           , vrDadosCliente.clientefontest
           , vrDadosCliente.sulframa
           , vrDadosCliente.tipoempresa
           , vrDadosCliente.orgaopub
           , vrDadosCliente.orgaopubmunicipal
           , vrDadosCliente.orgaopubfederal
           , vrDadosCliente.estent
           , vrDadosCliente.contribuinte
        FROM PCCLIENT
       WHERE (PCCLIENT.CODCLI = pi_nCodCli);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
    
    -- DDVENDAS-33718 - UF do Endereço de Entrega
    IF (pi_vEstEnt IS NOT NULL) THEN
      vrDadosCliente.estent := pi_vEstEnt;
    END IF;

    -- Pesquisa Dados o Produto
    BEGIN
      SELECT confaz
           , compraconsignado
        INTO vrDadosProduto.confaz
           , vrDadosProduto.compraconsignado
        FROM PCPRODUT
       WHERE (PCPRODUT.CODPROD = pi_nCodProd);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;

    -- Pesquisa Dados da Tributação
    BEGIN
      SELECT PCTRIBUT.*
        INTO vrDadosTributacao.Tributacao
        FROM PCTRIBUT
       WHERE (PCTRIBUT.CODST = pi_nCodSt);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;

    -- Pesquisa Dados da Filial
    BEGIN
      SELECT industria
           , uf
        INTO vrDadosFilial.industria
           , vrDadosFilial.uf
        FROM PCFILIAL
       WHERE (PCFILIAL.CODIGO = pi_vCodFilial);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;

    -- Pesquisa Dados da PCCONSUM
    BEGIN
      SELECT NVL(consideraisentoscomopf, 'S')
           , NVL(usartributacaotransftv10,'N')
        INTO vrDadosConsum.consideraisentoscomopf
           , vrDadosConsum.usartributacaotransftv10
        FROM PCCONSUM;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vrDadosConsum.consideraisentoscomopf   := 'N';
        vrDadosConsum.usartributacaotransftv10 := 'N';
    END;

    ---------------------------------
    -- Identificador de Pessoa Fisica
    ---------------------------------
    vbpessoafisica := FALSE;
    --DDMEDICA-3476
    IF (NVL(vrDadosCliente.Forceclipf,'N')= 'S') THEN
      vbpessoafisica := TRUE;    
    ELSIF    (NVL(vrDadosCliente.consumidorfinal,'N') = 'S') THEN
      vbpessoafisica := TRUE;
    ELSIF (((vrDadosCliente.tipofj = 'F') AND
          (NVL(vrDadosCliente.utilizaiesimplificada,'N') = 'N')) OR
          (NVL(vrDadosCliente.consumidorfinal,'N') = 'S') OR
          ((NVL(vrDadosConsum.consideraisentoscomopf,'S') = 'S') AND
          ((vrDadosCliente.ieent IS NULL) OR (vrDadosCliente.ieent = 'ISENTO') OR
          (vrDadosCliente.ieent = 'ISENTA')))) AND
          (NVL(vrDadosCliente.contribuinte,'N') = 'N') THEN
      vbpessoafisica := TRUE;
    END IF;

    ------------------------------
    -- Controle de Item Bonificado
    ------------------------------
    vvBonific := pi_vBonific;
    IF (vvBonific = 'S') THEN
      -- Pesquisa Parâmetro
      BEGIN
        SELECT NVL(VALOR,'N')
          INTO vMEDRETIRARSTBNFESTADUAL
          FROM PCPARAMFILIAL
         WHERE (CODFILIAL = pi_vCodFilial)
           AND (NOME      = 'MEDRETIRARSTBNFESTADUAL');
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vMEDRETIRARSTBNFESTADUAL := 'N';
      END;
      -- Se não usa Regime Especial Santa Catarina
      IF (NVL(vMEDRETIRARSTBNFESTADUAL,'N') <> 'S') THEN
        -- Item Bonificado é sempre "F", exceto quando usa Regime Especial Catarina
        vvBonific := 'F';
      END IF;
    END IF;

    ------------------------------------------
    -- Identificador de Item Bonificado em TV1
    ------------------------------------------
    vvItemTv1Bnf := 'N';
    IF (pi_nCondVenda = 1) AND
       (vvBonific  = 'F') THEN
      vvItemTv1Bnf := 'S';
    END IF;

    -------------------------------------------------------
    -- Identificador de Regime Especial de Isenção ST Fonte
    -------------------------------------------------------
    IF (pi_vRegimeEspIsenStFonte IS NULL) THEN
      -- Se Orgão Público e a Tributação tem Isenção de ST para Órgãos Públicos
      IF    ((NVL(vrDadosCliente.tipoclimed, ' ') IN ('D','E','M')) AND
             (NVL(vrDadosTributacao.Tributacao.isencaostorgaopub, ' ') = 'S')) THEN
        vvRegimeEspIsenStFonte := 'N';
      -- Se Cliente Usa Regime Especial Isenção ST Fonte e
      -- Tributação com Regime Especial Isenção ST Fonte
      ELSIF ((NVL(vrDadosCliente.usaregimeespisenstfonte,'N') = 'S') AND
             (NVL(vrDadosTributacao.Tributacao.regimeespisenstfonte,'N') = 'S')) THEN
        vvRegimeEspIsenStFonte := 'S';
      ELSE
        vvRegimeEspIsenStFonte := 'N';
      END IF;
    ELSE
      -- Se já definiu o valor no procedimento chamador
      vvRegimeEspIsenStFonte := pi_vRegimeEspIsenStFonte;
    END IF;


    -----------------------------------
    -- Busca CFOP e Situação Tributária
    -----------------------------------
    definircodfiscalpcmov(vrDadosCliente.calculast,
                          vrDadosProduto.confaz,
                          vrDadosTributacao.Tributacao.iva,
                          vrDadosTributacao.Tributacao.pauta,
                          vrDadosCliente.clientefontest,
                          vrDadosTributacao.Tributacao.ivafonte,
                          vrDadosTributacao.Tributacao.aliqicms1fonte,
                          vrDadosTributacao.Tributacao.aliqicms2fonte,
                          vrDadosTributacao.Tributacao.codfiscalisentost,
                          vrDadosTributacao.Tributacao.codfiscalisentostinter,
                          vrDadosTributacao.Tributacao.codfiscalisentostinternasc,
                          vrDadosTributacao.Tributacao.sittributisentost,
                          vbpessoafisica,
                          pi_nCondVenda,
                          vrDadosTributacao.Tributacao.codfiscalpf,
                          vrDadosTributacao.Tributacao.codfiscalinterpf,
                          vrDadosTributacao.Tributacao.codfiscalinternascpf,
                          vrDadosTributacao.Tributacao.sittributpf,
                          vrDadosCliente.sulframa,
                          pi_nVlDescSuframa,
                          vrDadosFilial.industria,
                          pi_nNumNotaConsign,
                          vrDadosTributacao.Tributacao.codfiscalmercconsig,
                          vrDadosTributacao.Tributacao.codfiscalmercconsiginter,
                          vrDadosTributacao.Tributacao.codfiscalmercconsiginternasc,
                          vrDadosTributacao.Tributacao.codfiscalbonific,
                          vrDadosTributacao.Tributacao.codfiscalbonificinter,
                          vrDadosTributacao.Tributacao.codfiscalbonificinternasc,
                          vrDadosTributacao.Tributacao.codfiscalvendaentfut,
                          vrDadosTributacao.Tributacao.codfiscalvendaentfutinter,
                          vrDadosTributacao.Tributacao.codfiscalsimpentfut,
                          vrDadosTributacao.Tributacao.codfiscalsimpentfutinter,
                          vrDadosTributacao.Tributacao.codfiscaltransf,
                          vrDadosTributacao.Tributacao.codfiscaltransfinter,
                          vrDadosTributacao.Tributacao.codfiscaltransfinternasc,
                          vrDadosTributacao.Tributacao.codfiscaltroca,
                          vrDadosTributacao.Tributacao.codfiscaltrocainter,
                          vrDadosTributacao.Tributacao.codfiscaltrocainternasc,
                          vrDadosTributacao.Tributacao.codfiscalprontaent,
                          vrDadosTributacao.Tributacao.codfiscalprontaentinter,
                          vrDadosTributacao.Tributacao.codfiscalprontaentinternasc,
                          vrDadosTributacao.Tributacao.codfiscalvendaprontaent,
                          vrDadosTributacao.Tributacao.codfiscalvendaprontaentinter,
                          vrDadosTributacao.Tributacao.codfiscalvendaconsig,
                          vrDadosTributacao.Tributacao.codfiscalvendaconsiginter,
                          vrDadosTributacao.Tributacao.codfiscalvendaconsiginternasc,
                          NULL, -- serieecf,
                          pi_vTipoCfopTv4,
                          pi_vCodCob,
                          pi_nPVenda,
                          vrDadosCliente.tipoempresa,
                          vrDadosTributacao.Tributacao.sittributnrpa,
                          pi_vProntaEntrega,
                          pi_vUsaCfopVendaNaTv10,
                          vrDadosTributacao.Tributacao.codfiscaltv9,
                          vrDadosTributacao.Tributacao.codfiscalintertv9,
                          vrDadosTributacao.Tributacao.codfiscalinternasctv9,
                          vrDadosProduto.compraconsignado,
                          vrDadosTributacao.Tributacao.codfiscalconsig,
                          vrDadosTributacao.Tributacao.codfiscalconsiginter,
                          vrDadosTributacao.Tributacao.codfiscalconsiginternac,
                          pi_vVendaTriangular,
                          vrDadosTributacao.Tributacao.codfiscaltriangular,
                          vrDadosTributacao.Tributacao.codfiscaltriangularinter,
                          vrDadosTributacao.Tributacao.codfiscaltriangularinternasc,
                          vrDadosTributacao.Tributacao.codfiscaltriangularpf,
                          vrDadosTributacao.Tributacao.codfiscaltriangularinterpf,
                          vrDadosTributacao.Tributacao.codfiscaltriangularinternascpf,
                          vrDadosTributacao.Tributacao.codfiscalcontaordem,
                          vrDadosTributacao.Tributacao.codfiscalcontaordeminter,
                          vrDadosTributacao.Tributacao.codfiscalcontaordemsimpent,
                          vrDadosTributacao.Tributacao.codfiscalcontaordemsimpentinte,
                          pi_vContaOrdem,
                          vrDadosRetornoCfop.vncfoest,               -->> RETORNO
                          vrDadosRetornoCfop.vncfointer,             -->> RETORNO
                          vrDadosRetornoCfop.vncfointernasc,         -->> RETORNO
                          vrDadosRetornoCfop.vssittribut,            -->> RETORNO
                          vrDadosRetornoCfop.vsusacfopbnfparabrinde, -->> RETORNO
                          pi_nCodBnf,
                          vrDadosRetornoCfop.vssittributtv7,         -->> RETORNO
                          pi_vFornecEntrega,
                          vvBonific,
                          vrDadosTributacao.Tributacao.sittributbonific,
                          vrDadosTributacao.Tributacao.isentaicmsbonific,
                          vrDadosTributacao.Tributacao.sittributbnftv1,
                          vvItemTv1Bnf,
                          vvRegimeEspIsenStFonte,
                          vrDadosCliente.tipoclimed,
                          vrDadosTributacao.Tributacao.utilizanatopsrtv20,
                          vrDadosTributacao.Tributacao.codfiscalsrestsr,
                          vrDadosTributacao.Tributacao.codfiscalsrinte,
                          vrDadosTributacao.Tributacao.codfiscalsrext,
                          pi_nNumTransEntOrigConsig,
                          vrDadosTributacao.Tributacao.sittributorgaopub,
                          vrDadosCliente.orgaopub,
                          vrDadosCliente.orgaopubmunicipal,
                          vrDadosCliente.orgaopubfederal,
                          vrDadosTributacao.Tributacao.codicmsimplesnac,  --HIS.00875.2013 --ICMS_SN
                          vrDadosTributacao.Tributacao.sittributsimplesnac, --HIS.00875.2013 --ICMS_SN
                          NULL, -- numped,
                          NULL, -- caregamento
                          NULL,  -- numtransacaovenda
                          po_vTipoCodFiscal,
                          po_vTipoSitTrib,
                          vvLogProcMed -- DDMEDICA-6772
                          );


    -- Tarefa 114260 (Bonificação do tipo degustação)
    IF (pi_nCondVenda = 5) AND (pi_nCodBnf = 4) AND
       (NVL(pi_nCfopNfDegusta,0) > 0) THEN
      vrDadosRetornoCfop.vncfoest       := pi_nCfopNfDegusta;
      vrDadosRetornoCfop.vncfointer     := pi_nCfopNfDegusta;
      vrDadosRetornoCfop.vncfointernasc := pi_nCfopNfDegusta;
      -- HIS.03261.2016
      po_vTipoCodFiscal := 'pi_nCfopNfDegusta > ' || vrDadosRetornoCfop.vncfoest;
    END IF;

    -------------------------------------
    -- Redefinição da Situação Tributária
    -------------------------------------
    IF (vrDadosTributacao.Tributacao.codicmpf IS NOT NULL) AND (vbpessoafisica = TRUE) AND
       (pi_nCondVenda <> 7) THEN
      vrDadosRetornoCfop.vssittribut := vrDadosTributacao.Tributacao.sittributpf;
      -- HIS.03261.2016
      po_vTipoSitTrib   := 'sittributpf pessoa fisica > ' || vrDadosRetornoCfop.vssittribut;
    END IF;

    -- HIS.02113.2017 - Regra Especifica Priorizar CST Órgão Público sobre o CST de Pessoa Fisica
    IF (vvPRIORIZACAOCSTORGAOPUBPF = 'S') THEN
     IF (vbpessoafisica = TRUE) AND
        ((NVL(vrDadosCliente.orgaopub,'N') = 'S')                 OR
         (NVL(vrDadosCliente.orgaopubfederal,'N') = 'S')          OR
         (NVL(vrDadosCliente.orgaopubmunicipal,'N') = 'S')        OR
         (nvl(vrDadosCliente.tipoclimed,' ') IN ('D','E','M'))  ) THEN
        vrDadosRetornoCfop.vssittribut := vrDadosTributacao.Tributacao.sittributorgaopub;
        -- Histórico
        po_vTipoSitTrib := 'Priorizar CST Órgão Público sobre PF > ' || vrDadosRetornoCfop.vssittribut;
      END IF;
    END IF;

    IF vrDadosCliente.tipoempresa = 'NRPA' THEN
      vrDadosRetornoCfop.vssittribut := vrDadosTributacao.Tributacao.sittributnrpa;
      -- HIS.03261.2016
      po_vTipoSitTrib   := 'NRPA > ' || vrDadosRetornoCfop.vssittribut;
    END IF;

    IF (vvBonific = 'S' and pi_nCondVenda = 1) THEN
      vrDadosRetornoCfop.vssittribut := '40';
      -- HIS.03261.2016
      po_vTipoSitTrib   := 'vvBonific = S and pi_nCondVenda = 1 > ' || vrDadosRetornoCfop.vssittribut;
    END IF;

    -- Tarefa 46966
    IF (NVL(vrDadosConsum.usartributacaotransftv10,'N') = 'S') AND
       (pi_nCondVenda = 10) THEN
      vrDadosRetornoCfop.vssittribut := vrDadosTributacao.Tributacao.sittributtransf;
      -- HIS.03261.2016
      po_vTipoSitTrib   := 'usartributacaotransftv10 e pi_nCondVenda = 10 > ' || vrDadosRetornoCfop.vssittribut;
    END IF;

    /*
    DESCRIÇÃO DA ALTERAÇÃO:
    Alterar a definição do CFOP e CST na Package de Faturamento, nas Vendas para Clientes
    que são Órgãos Públicos e para os Produtos que estão Tributados com Isenção de ST
    para Órgãos Públicos. Limitar a distribuidores de medicamentos.
    */
    IF --(nvl(vsutilizacontrolemedicamentos,'N') = 'S') AND
       (pi_nCondVenda = 1) AND
       (nvl(vrDadosCliente.tipoclimed,' ') IN ('D','E','M')) AND
       ((nvl(vrDadosTributacao.Tributacao.isencaoicmsorgaopub,'N') = 'S') or (nvl(vrDadosTributacao.Tributacao.isencaostorgaopub,'N') = 'S')) THEN
      vrDadosRetornoCfop.vncfoest    := vrDadosTributacao.Tributacao.codfiscalveniseorgaopubest;
      vrDadosRetornoCfop.vncfointer  := vrDadosTributacao.Tributacao.codfiscalveniseorgaopubinter;
      vrDadosRetornoCfop.vssittribut := vrDadosTributacao.Tributacao.sittributiseorgaopub;
      -- HIS.03261.2016
      po_vTipoCodFiscal := 'tipoclimed D, E, M isencao orgaopub > ' || vrDadosRetornoCfop.vncfoest;
      po_vTipoSitTrib   := 'tipoclimed D, E, M isencao orgaopub > ' || vrDadosRetornoCfop.vssittribut;
    END IF;

    IF (pi_nCondVenda = 1) AND
       (NVL(pi_nNumNotaConsign,0) > 0) AND
       (nvl(vrDadosCliente.tipoclimed,' ') <> 'H') THEN
       --(NVL(vsICMSDEVCONSIGDIFHOSP,'S') = 'N') THEN
      -- Pesquisa Parâmetro
      BEGIN
        SELECT NVL(VALOR,'S')
          INTO vDESTACARICMSDEVCONSIGDIFHOSP
          FROM PCPARAMFILIAL
         WHERE (CODFILIAL = '99')
           AND (NOME      = 'DESTACARICMSDEVCONSIGDIFHOSPITAL');

        --DDMEDICA-898
        BEGIN
          SELECT NVL(VALOR,'N')
            INTO vFILOPTANTESIMPLESNAC
            FROM PCPARAMFILIAL
           WHERE (CODFILIAL = pi_vCodFilial)
             AND (NOME      = 'FIL_OPTANTESIMPLESNAC');
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vFILOPTANTESIMPLESNAC := 'N';
        END;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vDESTACARICMSDEVCONSIGDIFHOSP := 'S'; -->> Default S-Sim
      END;
      IF (NVL(vDESTACARICMSDEVCONSIGDIFHOSP,'S') = 'N') AND (NVL(vFILOPTANTESIMPLESNAC,'N') <> 'S') THEN
        vrDadosRetornoCfop.vssittribut := '40';
        -- HIS.03261.2016
        po_vTipoSitTrib  := 'pi_nNumNotaConsign > 0 e tipoclimed <> H > ' || vrDadosRetornoCfop.vssittribut;
      END IF;
    END IF;

    -- HIS.03678.2017 - Se sistema aplicar redução p. física para hospitais e órgãos públicos
    IF vrDadosTributacao.Tributacao.utilizapercbaseredpfhosporgpub = 'S' THEN
      -- Se Cliente é Hospital ou Órgão Público Federal/Estadual/Municipal
      IF vrDadosCliente.tipoclimed IN ('H','D','E','M') THEN
        -- Se informado o CST para redução p. física para hospitais e órgãos públicos
        IF (vrDadosTributacao.Tributacao.sittribredpfhosporgpub IS NOT NULL) THEN
          vrDadosRetornoCfop.vssittribut := vrDadosTributacao.Tributacao.sittribredpfhosporgpub;
          -- LOG
          po_vTipoSitTrib  := 'sittribredpfhosporgpub > ' || vrDadosRetornoCfop.vssittribut;
        END IF;
      END IF;
    END IF;

    IF (pi_nCondVenda = 20) THEN
        -- Tratamento específico consignado
        IF (TRIM(vrDadosTributacao.Tributacao.sittributtv20) IS NOT NULL) THEN
          vrDadosRetornoCfop.vssittribut := vrDadosTributacao.Tributacao.sittributtv20;
          -- HIS.03261.2016
          po_vTipoSitTrib  := 'sittributtv20 > ' || vrDadosRetornoCfop.vssittribut;
        ELSE
          --IF (nvl(vsutilizacontrolemedicamentos,'N') = 'S') THEN
          IF NVL(vrDadosTributacao.Tributacao.utilizapercbaseredvenconsign,'N') = 'N' THEN
            vrDadosRetornoCfop.vssittribut := '00';
            -- HIS.03261.2016
            po_vTipoSitTrib := 'utilizapercbaseredvenconsign = N > ' || vrDadosRetornoCfop.vssittribut;
          END IF;
          --END IF;
        END IF;
    END IF;

    -----------
    -- Retornos
    -----------
    CASE vrDadosCliente.estent
      WHEN 'EX' THEN
        po_nCodFiscal := vrDadosRetornoCfop.vncfointernasc;
      WHEN vrDadosFilial.uf THEN
        po_nCodFiscal := vrDadosRetornoCfop.vncfoest;
      ELSE
        po_nCodFiscal := vrDadosRetornoCfop.vncfointer;
    END CASE;
    po_vSitTrib := vrDadosRetornoCfop.vssittribut;

  END P_DEFINIR_CODFISCAL;

  /*******************************************************************************
   Nome         : PRC_MED_OBTER_COMISSAO
   Descricão    : Procedimento para Obter a Comissão para os critérios estabelecidos
                  nos Parãmetros
   Parâmetros   : ENTRADA:
                  pi_nTipoChamada          = 1 - Chamado da 2316
                                             2 - Chamado da 2308 (Recálculo)
                                             3 - Chamado para Obter a Comissão Diferenciada Farma/Hospitalar
                                             4 - Procedure Valida Promoção
                  pi_nTipoDefinicaoComiss  = 1 - Obter a Comissão do Representante
                                             2 - Obter a Comissão do Televendas
                                                 como RCA2
                                             3 - Obter a Comissão do RCA2 (Não precisa ser o Emitente)
                  pi_nCodPromocaoMed       = Código da Promoção do Item do Pedido
                  pi_nCodProd              = Código do Produto
                  pi_nCodCli               = Código do Cliente
                  pi_dData                 = Data Base a ser considerada nas Consultas
                  pi_vCodFilial            = Código da Filial
                  pi_nNumRegiao            = Região do Cliente
                  pi_nCodUsur              = Código Vendedor
                  pi_nMatricula            = Matricula do Funcionário logado no Sistema
                  pi_vOrigemPed            = Origem do Pedido
                  pi_vTipoFv               = Tipo de Pedido Força de Vendas [FV;OL;PE]
                  pi_nCodPlPag             = Código do Plano de Pagamento
                  pi_nQtde                 = Quantidade
                  pi_nPerDesc              = Percentual de Desconto
                  pi_nCodDesconto          = Código do Desconto
                  pi_vTipoComissao         = Se for para pesquisar somente um tipo de comissão,
                                             passar ele aqui.
                                             'RA' - RCA/Ramo Atividade
                  pi_nCodEdital            = Código do Edital
                  SAIDA:
                  po_nPerCom               = Percentual de Comissão
                  po_vOcorreramErros       = Se Ocorreram Erros [S-Sim;N-Não]
                  po_vMsgErros             = Mensagem de Erro
   Alteracão    : Anderson Silva   - 23/05/2015 - Criação da Procedure
   Alteracão    : Anderson Silva   - 19/06/2015 - HIS.00802.2015 - Comissionamento da Equipe de Vendas 
                                                                   (Comissão por Cliente) 
                : Anderson Silva - 08/10/2015 - HIS.03333.2015 - Informações para
                                                                 Recálculo Comissão Compartilhada
                : Anderson Silva - 02/12/2015 - 5232.133953.2015 - Comissão Produto/Filial                                                              
                : Anderson Silva - 04/12/2015 - HIS.02846.2015   - Comissão por Ramo Atividade
                : Anderson Silva - 24/03/2016 - Ordem Comissão
                : Anderson Silva - 28/11/2016 - HIS.02082.2016 - Comissão Licitação
                : Anderson Silva - 01/02/2017 - HIS.00118.2017 - Comissão por Faixa de Rentabilidade
                                                opção 3 para o parâmetro pi_nTipoChamada
   Alteração    : Anderson Silva    = 24/02/2017 - Chamada 4 na Proc. PRC_MED_OBTER_COMISSAO
   Alteração    : Anderson Silva - 24/04/2017 - HIS.00665.2017 - Comissões com pedidos de promoção combo zeradas
                : Anderson Silva - 03/08/2017 - HIS.02819.2017 - Comissão Rentabilidade Compartilhada por Liquidez
                : Anderson Silva - 09/11/2017 - HIS.04185.2017 - Regra Específica Comissão Pacote - Retornar Tipo Comissão no Recálculo              
                : Anderson Silva - 20/05/2019 - MED-2595 - Comissão por Grupo
  ********************************************************************************/
  -- SE ALTERAR ESTE PROCEDIMENTO, ALTERAR TAMBÉM NA PKG_COMISSAO_MED
  PROCEDURE P_OBTER_COMISSAO(pi_nTipoChamada         IN  NUMBER,
                             pi_nTipoDefinicaoComiss IN  NUMBER,
                             pi_nCodPromocaoMed      IN  NUMBER,
                             pi_nCodProd             IN  NUMBER,
                             pi_nCodCli              IN  NUMBER,
                             pi_dData                IN  DATE,
                             pi_vCodFilial           IN  VARCHAR2,
                             pi_nNumRegiao           IN  NUMBER,
                             pi_nCodUsur             IN  NUMBER,
                             pi_nMatricula           IN  NUMBER,
                             pi_vOrigemPed           IN  VARCHAR2,
                             pi_vTipoFv              IN  VARCHAR2,
                             pi_nCodPlPag            IN  NUMBER,
                             pi_nQtde                IN  NUMBER,
                             pi_nPerDesc             IN  NUMBER,
                             pi_nCodDesconto         IN  NUMBER,
                             pi_vTipoComissao        IN  VARCHAR2, 
                             po_nPerCom              OUT NUMBER,                                       
                             po_vOcorreramErros      OUT VARCHAR2,
                             po_vMsgErros            OUT VARCHAR2,
                             pi_nCodEdital           IN  NUMBER DEFAULT 0)
  IS
  
    -- Parâmetros
    TYPE TRecParametros IS RECORD(
         vUSACOMISSAOPORRCA      PCCONSUM.USACOMISSAOPORRCA%TYPE,
         vCOMISSAORCATIPOVENDA   PCCONSUM.COMISSAORCATIPOVENDA%TYPE,
         vCONSIDERARCOMISSAOZERO PCFILIAL.CONSIDERARCOMISSAOZERO%TYPE,
         vUSACOMISSAOPORCLIENTE  PCCONSUM.USACOMISSAOPORCLIENTE%TYPE,
         nTIPOAVALIACAOCOMISSAO  PCFILIAL.TIPOAVALIACAOCOMISSAO%TYPE);
    vrParametros TRecParametros;
           
    -- Dados do Plano de Pagamento
    TYPE TRecPlPag IS RECORD(
         vTIPOVENDA              PCPLPAG.TIPOVENDA%TYPE);
    vrPlPag TRecPlPag;
  
    -- Dados do RCA
    TYPE TRecRca IS RECORD(
         vTIPOVEND               PCUSUARI.TIPOVEND%TYPE,
         nPERCENT                PCUSUARI.PERCENT%TYPE,
         nPERCENT2               PCUSUARI.PERCENT2%TYPE);
    vrRca TRecRca;
   
    -- Dados do Cliente
    TYPE TRecCliente IS RECORD(
         nCODATV1                PCCLIENT.CODATV1%TYPE);
    vrCliente TRecCliente;
         
    -- Dados do Funcionário
    TYPE TRecEmpr IS RECORD(
         nCODUSUR                PCEMPR.CODUSUR%TYPE);
    vrEmpr TRecEmpr;
  
    -- Dados do Produto
    TYPE TRecProd IS RECORD(
         nCODLINHAPROD           PCPRODUT.CODLINHAPROD%TYPE,
         nCODEPTO                PCPRODUT.CODEPTO%TYPE,
         nCODSEC                 PCPRODUT.CODSEC%TYPE
         );
    vrProd TRecProd;
  
    -- Pesquisa das Comissões
    vbTodasComissoes             BOOLEAN;
    vvTipoComissao               VARCHAR2(3);
    
    -- ARRAY para Ordem da Comissão
    TYPE TTOrdemComissao         IS TABLE OF VARCHAR2(3) INDEX BY BINARY_INTEGER;
    vtOrdemComissao              TTOrdemComissao;
    viIdxOrigemComissao          INTEGER;
    
    -- Erro Tratado
    e_Tratado                    EXCEPTION;
    vvMsgErroTratado             VARCHAR2(250);
    
    -- Log
    vvTipoPromocao               PCPROMOCAOMED.TIPOPROMOCAO%TYPE;
    vvTipoComissaoMed            PCPEDI.TIPOCOMISSAOMED%TYPE;
    
    -- MED-2595
    vPriorizaComissao            PCPROMOCAOMED.PRIORIZACOMISSAO%TYPE;
  
   /********************************************************************
    MED-2595 - Função para Retornar o Percentual de Comissão da Promoção
    ********************************************************************/
    FUNCTION F_OBTER_COMISSAO_PROMOCAO(pi_nCodDesconto    IN NUMBER,
                                       pi_nCodPromocaoMed IN NUMBER,
                                       pi_vTipoVend       IN VARCHAR2,
                                       pi_nCodProd        IN NUMBER) RETURN NUMBER IS                                         
      -- Retorno
      vnRetPerCom        PCDESCONTO.PERCOMREP%TYPE;
      vnCodGrupoComissao PCPROMOCAOMED.CODGRUPOCOMISSAO%TYPE;
      vnCodMarca         PCPRODUT.CODMARCA%TYPE;
      
    BEGIN
    
      -- Pesquisa Grupo de Comissão
      BEGIN
        SELECT CASE WHEN (NVL(PRIORIZACOMISSAO,'N') = 'S') THEN
                 CODGRUPOCOMISSAO
               ELSE
                 NULL
               END
          INTO vnCodGrupoComissao
          FROM PCPROMOCAOMED
         WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnCodGrupoComissao := NULL;
      END;
      
      -- Se tem Grupo de Comissão
      IF (vnCodGrupoComissao > 0) THEN
      
        -- Pesquisa a Marca do Produto
        BEGIN
          SELECT CODMARCA
            INTO vnCodMarca
            FROM PCPRODUT
           WHERE (CODPROD = pi_nCodProd);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vnCodMarca := NULL;
        END;
        
        -- Pesquisa a Comissão
        BEGIN 
          SELECT T.PERCENTUAL 
            INTO vnRetPerCom
            FROM PCTABELACOMISSAOGRUPOMED T 
           WHERE T.CODGRUPO = vnCodGrupoComissao 
             AND (T.CAMPO  = 'MA')
             AND (T.CODIGO = vnCodMarca);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vnRetPerCom := 0;
        END;
            
      -- Se não tem Grupo de Comissão
      ELSE
          
        -- Pesquisa o Percentual de Comissão da Promoção
        BEGIN  
          SELECT DECODE(pi_vTipoVend
                       ,'I', PERCOMMINT
                       ,'E', PERCOMEXT
                       ,'R', PERCOMREP
                       ,0) PERCOM
            INTO vnRetPerCom                   
            FROM PCDESCONTO
           WHERE (PCDESCONTO.CODDESCONTO    = pi_nCodDesconto)
             AND (PCDESCONTO.CODPROMOCAOMED = pi_nCodPromocaoMed)
             AND (ROWNUM                    = 1);
        EXCEPTION 
          WHEN NO_DATA_FOUND THEN
            vnRetPerCom := 0;
        END;
        
      END IF;
      
      -- Retorno
      RETURN NVL(vnRetPerCom,0);
    
    END F_OBTER_COMISSAO_PROMOCAO; 
  
    -------------------------------------------------
    -- PROCEDURE: P_COMISSAO_REGIAOMED
    -- DESCRIÇÃO: Obter Comissão Diferenciada 
    --            Farma/Hospitalar informada na
    --            PCCOMISSAOREGIAOMED
    ------------------------------------------------
    PROCEDURE P_COMISSAO_REGIAOMED(pi_vConsiderarComissaoZero IN VARCHAR2,
                                   pi_vTipoVend               IN VARCHAR2,                           
                                   pi_vCodFilial              IN VARCHAR2,
                                   pi_nNumRegiao              IN NUMBER,
                                   pi_dData                   IN DATE,
                                   pi_nCodLinhaProd           IN NUMBER,
                                   pi_nCodepto                IN NUMBER,
                                   pi_nCodSec                 IN NUMBER,
                                   pi_nPerDesc                IN NUMBER,
                                   pio_nPerCom                IN OUT NUMBER)
    IS
      -- Cursor de Comissão Região por Produto
      CURSOR c_ComissRegProd(pi_vTipoVend     IN VARCHAR2,                           
                             pi_vCodFilial    IN VARCHAR2,
                             pi_nNumRegiao    IN NUMBER,
                             pi_dData         IN DATE,
                             pi_nCodLinhaProd IN NUMBER,
                             pi_nCodepto      IN NUMBER,
                             pi_nCodSec       IN NUMBER,
                             pi_nPerDesc      IN NUMBER) IS
        SELECT 1 PRIORIDADE,
               'RS' TIPOCOMISSAOMED,
               DECODE(NVL(TIPOVENDEDOR,'N'),'S', DECODE(pi_vTipoVend, 'I', NVL(PERCOMINT,0),
                                                                      'E', NVL(PERCOMEXT,0),
                                                                      'R', NVL(PERCOM,0)),
                                            PCCOMISSAOREGIAOMED.PERCOM) PERCOM
          FROM PCCOMISSAOREGIAOMED
         WHERE ((NUMREGIAO IS NULL) OR (NUMREGIAO = pi_nNumRegiao))
           AND (ROUND(NVL(pi_nPerDesc,0),2) BETWEEN PERDESCINI AND PERDESCFIM)
           AND (NVL(TIPO,'R') = 'RS')
           AND (CODSEC = pi_nCodSec) -->> POR SEÇÃO
           AND ((CODFILIAL IS NULL) OR (NVL(CODFILIAL,' ') = pi_vCodFilial))
           AND (TRUNC(pi_dData) BETWEEN NVL(DTINICIO, TRUNC(pi_dData)) AND NVL(DTFIM, TRUNC(pi_dData)))
        UNION   
        SELECT 2 PRIORIDADE,
               'RL' TIPOCOMISSAOMED,
               DECODE(NVL(TIPOVENDEDOR,'N'),'S', DECODE(pi_vTipoVend, 'I', NVL(PERCOMINT,0),
                                                                      'E', NVL(PERCOMEXT,0),
                                                                      'R', NVL(PERCOM,0)),
                                            PCCOMISSAOREGIAOMED.PERCOM) PERCOM
          FROM PCCOMISSAOREGIAOMED
         WHERE ((NUMREGIAO IS NULL) OR (NUMREGIAO = pi_nNumRegiao))
           AND (ROUND(NVL(pi_nPerDesc,0),2) BETWEEN PERDESCINI AND PERDESCFIM)
           AND (NVL(TIPO,'R') = 'RL')
           AND (CODLINHAPROD = pi_nCodLinhaProd) -->> POR LINHA DE PRODUTO
           AND ((CODFILIAL IS NULL) OR (NVL(CODFILIAL,' ') = pi_vCodFilial))
           AND (TRUNC(pi_dData) BETWEEN NVL(DTINICIO, TRUNC(pi_dData)) AND NVL(DTFIM, TRUNC(pi_dData)))
        UNION            
        SELECT 3 PRIORIDADE,
               'RD' TIPOCOMISSAOMED,
               DECODE(NVL(TIPOVENDEDOR,'N'),'S', DECODE(pi_vTipoVend, 'I', NVL(PERCOMINT,0),
                                                                      'E', NVL(PERCOMEXT,0),
                                                                      'R', NVL(PERCOM,0)),
                                            PCCOMISSAOREGIAOMED.PERCOM) PERCOM
          FROM PCCOMISSAOREGIAOMED
         WHERE ((NUMREGIAO IS NULL) OR (NUMREGIAO = pi_nNumRegiao))
           AND (ROUND(NVL(pi_nPerDesc,0),2) BETWEEN PERDESCINI AND PERDESCFIM)
           AND (NVL(TIPO,'R') = 'RD')
           AND (CODEPTO = pi_nCodepto) -->> POR DEPARTAMENTO
           AND ((CODFILIAL IS NULL) OR (NVL(CODFILIAL,' ') = pi_vCodFilial))
           AND (TRUNC(pi_dData) BETWEEN NVL(DTINICIO, TRUNC(pi_dData)) AND NVL(DTFIM, TRUNC(pi_dData)))
        UNION   
        SELECT 4 PRIORIDADE,
               'RR' TIPOCOMISSAOMED,
               DECODE(NVL(TIPOVENDEDOR,'N'),'S', DECODE(pi_vTipoVend, 'I', NVL(PERCOMINT,0),
                                                                      'E', NVL(PERCOMEXT,0),
                                                                      'R', NVL(PERCOM,0)),
                                            PCCOMISSAOREGIAOMED.PERCOM) PERCOM
          FROM PCCOMISSAOREGIAOMED
         WHERE ((NUMREGIAO IS NULL) OR (NUMREGIAO = pi_nNumRegiao))
           AND (ROUND(NVL(pi_nPerDesc,0),2) BETWEEN PERDESCINI AND PERDESCFIM)
           AND (NVL(TIPO,'R') = 'R') -->> POR REGIAO
           AND ((CODFILIAL IS NULL) OR (NVL(CODFILIAL,' ') = pi_vCodFilial))
           AND (TRUNC(pi_dData) BETWEEN NVL(DTINICIO, TRUNC(pi_dData)) AND NVL(DTFIM, TRUNC(pi_dData)))
         ORDER BY 1; -->> Ordenado pela Prioridade, ao achar o primeiro irá sair do Laço
      
    BEGIN
    
      -- Pesquisa a Comissão por Região e Produto
      FOR vc_ComissRegProd IN c_ComissRegProd(pi_vTipoVend,
                                              pi_vCodFilial,
                                              pi_nNumRegiao,
                                              pi_dData,
                                              pi_nCodLinhaProd,
                                              pi_nCodepto,
                                              pi_nCodSec,
                                              pi_nPerDesc) LOOP
                                              
        IF (vc_ComissRegProd.PERCOM IS NOT NULL) THEN
  
          IF (NVL(vc_ComissRegProd.PERCOM,0) = 0) THEN
            IF (NVL(pi_vConsiderarComissaoZero,'N') = 'S') THEN
              pio_nPerCom       := NVL(vc_ComissRegProd.PERCOM,0); 
              vvTipoComissaoMed := vc_ComissRegProd.TIPOCOMISSAOMED;
            END IF;
          ELSE
            pio_nPerCom       := NVL(vc_ComissRegProd.PERCOM,0); 
            vvTipoComissaoMed := vc_ComissRegProd.TIPOCOMISSAOMED;
          END IF;
        
        END IF;                                             
                                              
        -- Sai após achar o primeiro
        EXIT;
                                                    
      END LOOP; -- Fim Região e Produto
    
    END P_COMISSAO_REGIAOMED;
  
    ---------------------------------------------
    -- PROCEDURE: P_COMISSAO_RCA
    -- DESCRIÇÃO: Obter Comissão informada no RCA
    ---------------------------------------------
    PROCEDURE P_COMISSAO_RCA(pi_vUsaComissaoPorRca      IN VARCHAR2,
                             pi_vComissaoRcaTipoVenda   IN VARCHAR2,
                             pi_vConsiderarComissaoZero IN VARCHAR2,
                             pi_vTipoVenda              IN VARCHAR2,
                             pi_nPercent                IN NUMBER,
                             pi_nPercent2               IN NUMBER,
                             pi_nCodEdital              IN NUMBER,
                             pi_nCodUsur                IN NUMBER,
                             pio_nPerCom                IN OUT NUMBER)
    IS
      -- HIS.02082.2016
      vUSACOMISSAOLICITPEDVENDAMED VARCHAR(1);
      vvAchouPerComLicit           VARCHAR2(1);
      vnPerComLicit                NUMBER; 
      vnCodModalidadeLicit         NUMBER;
    BEGIN
    
      -- Se usa Comissão por RCA
      IF (NVL(pi_vUsaComissaoPorRca,'N') = 'S') THEN
      
        -- Se usa Comissão RCA por Tipo de Venda
        IF (NVL(pi_vComissaoRcaTipoVenda,'N') = 'S') THEN
        
          -- Comissão Venda à Vista
          IF    (NVL(pi_vTipoVenda,' ') = 'VV') AND
                (pi_nPercent IS NOT NULL)       THEN
                
            IF (NVL(pi_nPercent,0) = 0) THEN
              IF (NVL(pi_vConsiderarComissaoZero,'N') = 'S') THEN
                pio_nPerCom       := NVL(pi_nPercent,0); 
                vvTipoComissaoMed := 'RC';
              END IF;
            ELSE
              pio_nPerCom       := NVL(pi_nPercent,0); 
              vvTipoComissaoMed := 'RC';
            END IF;
                
          -- Comissão Venda a Prazo
          ELSIF (NVL(pi_vTipoVenda,' ') = 'VP') AND
                (pi_nPercent2 IS NOT NULL)      THEN
  
            IF (NVL(pi_nPercent2,0) = 0) THEN
              IF (NVL(pi_vConsiderarComissaoZero,'N') = 'S') THEN
                pio_nPerCom       := NVL(pi_nPercent2,0); 
                vvTipoComissaoMed := 'RC';
              END IF;
            ELSE
              pio_nPerCom       := NVL(pi_nPercent2,0); 
              vvTipoComissaoMed := 'RC';
            END IF;
                
          END IF;
        
        -- Se NÃO usa Comissão RCA por Tipo de Venda
        ELSE
        
          -- DDMEDICA-3545 - Não processar Comissão RCA Nula
          IF (pi_nPercent2 IS NOT NULL) THEN

            IF (NVL(pi_nPercent2,0) = 0) THEN
              IF (NVL(pi_vConsiderarComissaoZero,'N') = 'S') THEN
                pio_nPerCom       := NVL(pi_nPercent2,0); 
                vvTipoComissaoMed := 'RC';
              END IF;
            ELSE
              pio_nPerCom       := NVL(pi_nPercent2,0); 
              vvTipoComissaoMed := 'RC';
            END IF;
            
          END IF;
        
        END IF; -- Fim Condição Se usa Comissão RCA por Tipo de Venda
      
      END IF; -- Fim Condição Se usa Comissão por RCA
      
      -- Comissão do RCA da Licitação -- HIS.02082.2016
      IF (pi_nCodEdital > 0) THEN
      
        -- Verifica se usa a Comissão da Licitação
        BEGIN
          EXECUTE IMMEDIATE ' SELECT USACOMISSAOLICITPEDVENDAMED 
                                FROM PCCONFIGLICITACAO 
                               WHERE (CODFILIAL  = ' || '''' || '99' || '''' || ')' 
                       INTO vUSACOMISSAOLICITPEDVENDAMED;      
        EXCEPTION    
          WHEN NO_DATA_FOUND THEN
            vUSACOMISSAOLICITPEDVENDAMED := 'N';
          WHEN OTHERS THEN
            vUSACOMISSAOLICITPEDVENDAMED := 'N';      
        END;
        
        -- Se utiliza Comissão da Licitação
        IF (vUSACOMISSAOLICITPEDVENDAMED = 'S') THEN
        
          -- Inicializa Valores
          vvAchouPerComLicit := 'N';
          vnPerComLicit      := NULL;      
        
          -- Pesquisa Modalidade 
          BEGIN
            EXECUTE IMMEDIATE ' SELECT CODMODALIDADE 
                                  FROM PCEDITAIS 
                                 WHERE (CODEDITAL  = ' || NVL(pi_nCodEdital,0) || ')' 
                         INTO vnCodModalidadeLicit;      
          EXCEPTION    
            WHEN NO_DATA_FOUND THEN
              vnCodModalidadeLicit := NULL;
            WHEN OTHERS THEN
              vnCodModalidadeLicit := NULL;
          END;
          
          -- Se achou a Modalidade
          IF (vnCodModalidadeLicit > 0) THEN
          
            -- Pesquisa Comissão da Modalidade - GERAL
            BEGIN
              EXECUTE IMMEDIATE ' SELECT ''S'' ACHOU 
                                       , PERCOM 
                                    FROM PCLICITCOMISSAOUSUR 
                                   WHERE (CODUSUR      = 0)
                                     AND (TIPOUNIVERSO = ''ML'')
                                     AND (CODUNIVERSO  = ' || '''' || NVL(vnCodModalidadeLicit,0) || '''' || ')' 
                           INTO vvAchouPerComLicit
                              , vnPerComLicit;      
            EXCEPTION    
              WHEN NO_DATA_FOUND THEN
                vvAchouPerComLicit := 'N';
              WHEN OTHERS THEN
                vvAchouPerComLicit := 'N';
            END;      
            
            -- Se não achou Geral, procura por RCA
            IF (NVL(vvAchouPerComLicit,'N') = 'N') THEN
              BEGIN
                EXECUTE IMMEDIATE ' SELECT ''S'' ACHOU 
                                         , PERCOM 
                                      FROM PCLICITCOMISSAOUSUR 
                                     WHERE (CODUSUR      = ' || NVL(pi_nCodUsur,0) || ' )
                                       AND (TIPOUNIVERSO = ''ML'')
                                       AND (CODUNIVERSO  = ' || '''' || NVL(vnCodModalidadeLicit,0) || '''' || ')' 
                             INTO vvAchouPerComLicit
                                , vnPerComLicit;      
              EXCEPTION    
                WHEN NO_DATA_FOUND THEN
                  vvAchouPerComLicit := 'N';
                WHEN OTHERS THEN
                  vvAchouPerComLicit := 'N';
              END;      
            END IF;  
          
          END IF; -- Fim Condição Se achou a Modalidade
          
          -- Se achou um Registro que atenda a Modalidade
          IF (vvAchouPerComLicit = 'S') THEN
            IF (NVL(vnPerComLicit,0) = 0) THEN
              IF (NVL(pi_vConsiderarComissaoZero,'N') = 'S') THEN
                pio_nPerCom       := NVL(vnPerComLicit,0); 
                vvTipoComissaoMed := 'LI';
              END IF;
            ELSE
              pio_nPerCom       := NVL(vnPerComLicit,0); 
              vvTipoComissaoMed := 'LI';
            END IF;
          END IF;        
        
        END IF; -- Fim Condição Se utiliza Comissão da Licitação
      
      END IF; -- Fim Condição Comissão do RCA da Licitação
    
    END P_COMISSAO_RCA;
  
    ---------------------------------------------------------
    -- PROCEDURE: P_COMISSAO_RAMO_ATIVIDADE
    -- DESCRIÇÃO: Obter Comissão informada por Ramo Atividade
    ---------------------------------------------------------
    PROCEDURE P_COMISSAO_RAMO_ATIVIDADE(pi_vConsiderarComissaoZero IN VARCHAR2,
                                        pi_vTipoVend               IN VARCHAR2,                           
                                        pi_nCodUsur                IN NUMBER,
                                        pi_nCodAtiv                IN NUMBER,
                                        pio_nPerCom                IN OUT NUMBER)
    IS
      vnPerComAtiv PCCOMISSAOMED.PERCOMREP%TYPE;
    BEGIN
    
      -- Somente pesquisa a Comissão por Cliente (Não tem Comissão de Operador por Filial)
      BEGIN
        SELECT DECODE(pi_vTipoVend
                     ,'I',   PERCOMINT
                     ,'E',   PERCOMEXT
                     ,'R',   PERCOMREP
                     ,0) PERCOM
          INTO vnPerComAtiv                     
          FROM PCCOMISSAOMED
         WHERE (PCCOMISSAOMED.CODFILIAL        = '99')
           AND (PCCOMISSAOMED.CODIGOPRINCIPAL  = pi_nCodUsur)
           AND (PCCOMISSAOMED.CODIGOSECUNDARIO = pi_nCodAtiv)
           AND (PCCOMISSAOMED.TIPOCOMISSAO     = 'RA');
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnPerComAtiv := NULL;
      END;
                
      IF (vnPerComAtiv IS NOT NULL) THEN
  
        IF (NVL(vnPerComAtiv,0) = 0) THEN
          IF (NVL(pi_vConsiderarComissaoZero,'N') = 'S') THEN
            pio_nPerCom       := NVL(vnPerComAtiv,0); 
            vvTipoComissaoMed := 'RA';
          END IF;
        ELSE
          pio_nPerCom       := NVL(vnPerComAtiv,0); 
          vvTipoComissaoMed := 'RA';
        END IF;
        
      END IF;                                             
        
    END P_COMISSAO_RAMO_ATIVIDADE;
  
    -------------------------------------------------
    -- PROCEDURE: P_COMISSAO_CLIENTE
    -- DESCRIÇÃO: Obter Comissão informada no Cliente
    -------------------------------------------------
    PROCEDURE P_COMISSAO_CLIENTE(pi_vUsaComissaoPorCliente  IN VARCHAR2,
                                 pi_vConsiderarComissaoZero IN VARCHAR2,
                                 pi_vTipoVend               IN VARCHAR2,                           
                                 pi_nCodCli                 IN NUMBER,
                                 pio_nPerCom                IN OUT NUMBER)
    IS
      vnPerComCli PCCLIENT.PERCOMCLI%TYPE;
    BEGIN
    
      -- Se usa Comissão por Cliente
      IF (NVL(pi_vUsaComissaoPorCliente,'N') = 'S') THEN
        
        -- Somente pesquisa a Comissão por Cliente (Não tem Comissão de Operador por Filial)
        BEGIN
          SELECT DECODE(pi_vTipoVend
                       ,'I',   PERCOMINTMED
                       ,'E',   0 -->> Comissão por Cliente não tem coluna de Externo
                       ,'R',   PERCOMCLI
                       ,0) PERCOM
            INTO vnPerComCli                     
            FROM PCCLIENT
           WHERE (PCCLIENT.CODCLI = pi_nCodCli);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vnPerComCli := NULL;
        END;
                
        IF (vnPerComCli IS NOT NULL) THEN
  
          IF (NVL(vnPerComCli,0) = 0) THEN
            IF (NVL(pi_vConsiderarComissaoZero,'N') = 'S') THEN
              pio_nPerCom       := NVL(vnPerComCli,0); 
              vvTipoComissaoMed := 'CL';
            END IF;
          ELSE
            pio_nPerCom       := NVL(vnPerComCli,0); 
            vvTipoComissaoMed := 'CL';
          END IF;
        
        END IF;                                             
      
      END IF; -- Fim Condição Se usa Comissão por Cliente  
    
    END P_COMISSAO_CLIENTE;
    
    --------------------------------------------------
    -- PROCEDURE: P_COMISSAO_PRODUTO
    -- DESCRIÇÃO: Obter Comissão informada por Produto
    --------------------------------------------------
    PROCEDURE P_COMISSAO_PRODUTO(pi_vConsiderarComissaoZero IN VARCHAR2,
                                 pi_vTipoVend               IN VARCHAR2,                           
                                 pi_dData                   IN DATE,
                                 pi_nCodProd                IN NUMBER,
                                 pi_vCodFilial              IN VARCHAR2,
                                 pi_nPerDesc                IN NUMBER,
                                 pio_nPerCom                IN OUT NUMBER)
    IS   
      vnPerCom PCPRODUT.PCOMREP1%TYPE;
    BEGIN
    
      -- Pesquisa a Comissão por Produto
      BEGIN  
        SELECT DECODE(
                  ( SELECT COUNT( 1 )
                     FROM pcprodfilial
                    WHERE codprod = pi_nCodProd
                      AND codfilial = pi_vCodFilial )
                 ,0, DECODE(
                     pi_vTipoVend
                    ,'I', pcprodut.pcomint1
                    ,'E', pcprodut.pcomext1
                    ,'R', pcprodut.pcomrep1
                  )
                 ,( SELECT DECODE(
                              pi_vTipoVend
                             ,'I', NVL( pcprodfilial.pcomint1, pcprodut.pcomint1 )
                             ,'E', NVL( pcprodfilial.pcomext1, pcprodut.pcomext1 )
                             ,'R', NVL( pcprodfilial.pcomrep1, pcprodut.pcomrep1 )
                           )
                     FROM pcprodfilial
                    WHERE codprod = pi_nCodProd
                      AND codfilial = pi_vCodFilial )
               ) percom
          INTO vnPerCom       
          FROM pcprodut
         WHERE codprod = pi_nCodProd;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnPerCom := NULL;
      END;
  
      IF (vnPerCom IS NOT NULL) THEN
    
        IF (NVL(vnPerCom,0) = 0) THEN
          IF (NVL(pi_vConsiderarComissaoZero,'N') = 'S') THEN
            pio_nPerCom       := NVL(vnPerCom,0); 
            vvTipoComissaoMed := 'PR';
          END IF;
        ELSE
          pio_nPerCom       := NVL(vnPerCom,0); 
          vvTipoComissaoMed := 'PR';
        END IF;
          
      END IF;                                             
                                                
    END P_COMISSAO_PRODUTO;  
  
    --------------------------------------------------------------------------
    -- PROCEDURE: P_COMISSAO_USUR
    -- DESCRIÇÃO: Obter Comissão informada por Desconto e RCA - HIS.00665.2017
    --------------------------------------------------------------------------
    PROCEDURE P_COMISSAO_USUR(pi_vConsiderarComissaoZero IN VARCHAR2,
                              pi_nCodUsur                IN NUMBER,
                              pi_nCodProd                IN NUMBER,
                              pi_nCodepto                IN NUMBER,
                              pi_nCodSec                 IN NUMBER,
                              pi_nPerDesc                IN NUMBER,
                              pio_nPerCom                IN OUT NUMBER)
    IS
      -- Cursor de Comissão por Desconto e RCA
      CURSOR c_ComissDescRca(pi_nCodUsur      IN NUMBER,
                             pi_nCodProd      IN NUMBER,
                             pi_nCodepto      IN NUMBER,
                             pi_nCodSec       IN NUMBER,
                             pi_nPerDesc      IN NUMBER) IS
                             
        SELECT 1 PRIORIDADE,
               'UP' TIPOCOMISSAOMED,
               PERCOM
          FROM PCCOMISSAOUSUR
         WHERE (CODUSUR = pi_nCodUsur)
           AND (ROUND(NVL(pi_nPerDesc,0),2) BETWEEN PERCDESCINI AND PERCDESCFIM)
           AND (NVL(TIPO,'R') = 'RP')
           AND (CODPROD = pi_nCodProd) -->> POR PRODUTO
        UNION                     
        SELECT 2 PRIORIDADE,
               'US' TIPOCOMISSAOMED,
               PERCOM
          FROM PCCOMISSAOUSUR
         WHERE (CODUSUR = pi_nCodUsur)
           AND (ROUND(NVL(pi_nPerDesc,0),2) BETWEEN PERCDESCINI AND PERCDESCFIM)
           AND (NVL(TIPO,'R') = 'RS')
           AND (CODSEC = pi_nCodSec) -->> POR SEÇÃO
        UNION   
        SELECT 3 PRIORIDADE,
               'UD' TIPOCOMISSAOMED,
               PERCOM
          FROM PCCOMISSAOUSUR
         WHERE (CODUSUR = pi_nCodUsur)
           AND (ROUND(NVL(pi_nPerDesc,0),2) BETWEEN PERCDESCINI AND PERCDESCFIM)
           AND (NVL(TIPO,'R') = 'RD')
           AND (CODEPTO = pi_nCodepto) -->> POR DEPARTAMENTO
        UNION   
        SELECT 4 PRIORIDADE,
               'UR' TIPOCOMISSAOMED,
               PERCOM
          FROM PCCOMISSAOUSUR
         WHERE (CODUSUR = pi_nCodUsur) -->> POR RCA
           AND (ROUND(NVL(pi_nPerDesc,0),2) BETWEEN PERCDESCINI AND PERCDESCFIM)
           AND (NVL(TIPO,'R') = 'R') 
         ORDER BY 1; -->> Ordenado pela Prioridade, ao achar o primeiro irá sair do Laço    
    BEGIN
    
      -- Pesquisa a Comissão por Desconto e RCA
      FOR vc_ComissDescRca IN c_ComissDescRca(pi_nCodUsur,
                                              pi_nCodProd,
                                              pi_nCodepto,
                                              pi_nCodSec,
                                              pi_nPerDesc) LOOP
                                              
        IF (vc_ComissDescRca.PERCOM IS NOT NULL) THEN
  
          IF (NVL(vc_ComissDescRca.PERCOM,0) = 0) THEN
            IF (NVL(pi_vConsiderarComissaoZero,'N') = 'S') THEN
              pio_nPerCom       := NVL(vc_ComissDescRca.PERCOM,0); 
              vvTipoComissaoMed := vc_ComissDescRca.TIPOCOMISSAOMED;
            END IF;
          ELSE
            pio_nPerCom       := NVL(vc_ComissDescRca.PERCOM,0); 
            vvTipoComissaoMed := vc_ComissDescRca.TIPOCOMISSAOMED;
          END IF;
        
        END IF;                                             
                                              
        -- Sai após achar o primeiro
        EXIT;
                                                    
      END LOOP; -- Fim Desconto e RCA
    
    END P_COMISSAO_USUR;
    
    -------------------------------------------------
    -- PROCEDURE: P_COMISSAO_REGIAO
    -- DESCRIÇÃO: Obter Comissão informada por Região
    ------------------------------------------------
    PROCEDURE P_COMISSAO_REGIAO(pi_vConsiderarComissaoZero IN VARCHAR2,
                                pi_vTipoVend               IN VARCHAR2,                           
                                pi_vCodFilial              IN VARCHAR2,
                                pi_nNumRegiao              IN NUMBER,
                                pi_dData                   IN DATE,
                                pi_nCodProd                IN NUMBER,
                                pi_nCodLinhaProd           IN NUMBER,
                                pi_nCodepto                IN NUMBER,
                                pi_nCodSec                 IN NUMBER,
                                pi_nPerDesc                IN NUMBER,
                                pio_nPerCom                IN OUT NUMBER)
    IS
      -- Cursor de Comissão Região por Produto
      CURSOR c_ComissRegProd(pi_vTipoVend     IN VARCHAR2,                           
                             pi_vCodFilial    IN VARCHAR2,
                             pi_nNumRegiao    IN NUMBER,
                             pi_dData         IN DATE,
                             pi_nCodProd      IN NUMBER,
                             pi_nCodLinhaProd IN NUMBER,
                             pi_nCodepto      IN NUMBER,
                             pi_nCodSec       IN NUMBER,
                             pi_nPerDesc      IN NUMBER) IS
                             
        SELECT 1 PRIORIDADE,
               'RP' TIPOCOMISSAOMED,
               DECODE(NVL(TIPOVENDEDOR,'N'),'S', DECODE(pi_vTipoVend, 'I', NVL(PERCOMINT,0),
                                                                      'E', NVL(PERCOMEXT,0),
                                                                      'R', NVL(PERCOM,0)),
                                            PCCOMISSAOREGIAO.PERCOM) PERCOM
          FROM PCCOMISSAOREGIAO
         WHERE ((NUMREGIAO IS NULL) OR (NUMREGIAO = pi_nNumRegiao))
           AND (CODPROD = pi_nCodProd)
           AND (ROUND(NVL(pi_nPerDesc,0),2) BETWEEN PERDESCINI AND PERDESCFIM)
           AND (NVL(TIPO,'R') = 'P')
           AND ((CODFILIAL IS NULL) OR (NVL(CODFILIAL,' ') = pi_vCodFilial))
           AND (TRUNC(pi_dData) BETWEEN NVL(DTINICIO, TRUNC(SYSDATE)) AND NVL(DTFIM, TRUNC(SYSDATE)))
        UNION                     
        SELECT 2 PRIORIDADE,
               'RS' TIPOCOMISSAOMED,
               DECODE(NVL(TIPOVENDEDOR,'N'),'S', DECODE(pi_vTipoVend, 'I', NVL(PERCOMINT,0),
                                                                      'E', NVL(PERCOMEXT,0),
                                                                      'R', NVL(PERCOM,0)),
                                            PCCOMISSAOREGIAO.PERCOM) PERCOM
          FROM PCCOMISSAOREGIAO
         WHERE ((NUMREGIAO IS NULL) OR (NUMREGIAO = pi_nNumRegiao))
           AND (ROUND(NVL(pi_nPerDesc,0),2) BETWEEN PERDESCINI AND PERDESCFIM)
           AND (NVL(TIPO,'R') = 'RS')
           AND (CODSEC = pi_nCodSec) -->> POR SEÇÃO
           AND ((CODFILIAL IS NULL) OR (NVL(CODFILIAL,' ') = pi_vCodFilial))
           AND (TRUNC(pi_dData) BETWEEN NVL(DTINICIO, TRUNC(pi_dData)) AND NVL(DTFIM, TRUNC(pi_dData)))
        UNION   
        SELECT 3 PRIORIDADE,
               'RL' TIPOCOMISSAOMED,
               DECODE(NVL(TIPOVENDEDOR,'N'),'S', DECODE(pi_vTipoVend, 'I', NVL(PERCOMINT,0),
                                                                      'E', NVL(PERCOMEXT,0),
                                                                      'R', NVL(PERCOM,0)),
                                            PCCOMISSAOREGIAO.PERCOM) PERCOM
          FROM PCCOMISSAOREGIAO
         WHERE ((NUMREGIAO IS NULL) OR (NUMREGIAO = pi_nNumRegiao))
           AND (ROUND(NVL(pi_nPerDesc,0),2) BETWEEN PERDESCINI AND PERDESCFIM)
           AND (NVL(TIPO,'R') = 'RL')
           AND (CODLINHAPROD = pi_nCodLinhaProd) -->> POR LINHA DE PRODUTO
           AND ((CODFILIAL IS NULL) OR (NVL(CODFILIAL,' ') = pi_vCodFilial))
           AND (TRUNC(pi_dData) BETWEEN NVL(DTINICIO, TRUNC(pi_dData)) AND NVL(DTFIM, TRUNC(pi_dData)))
        UNION            
        SELECT 4 PRIORIDADE,
               'RD' TIPOCOMISSAOMED,
               DECODE(NVL(TIPOVENDEDOR,'N'),'S', DECODE(pi_vTipoVend, 'I', NVL(PERCOMINT,0),
                                                                      'E', NVL(PERCOMEXT,0),
                                                                      'R', NVL(PERCOM,0)),
                                            PCCOMISSAOREGIAO.PERCOM) PERCOM
          FROM PCCOMISSAOREGIAO
         WHERE ((NUMREGIAO IS NULL) OR (NUMREGIAO = pi_nNumRegiao))
           AND (ROUND(NVL(pi_nPerDesc,0),2) BETWEEN PERDESCINI AND PERDESCFIM)
           AND (NVL(TIPO,'R') = 'RD')
           AND (CODEPTO = pi_nCodepto) -->> POR DEPARTAMENTO
           AND ((CODFILIAL IS NULL) OR (NVL(CODFILIAL,' ') = pi_vCodFilial))
           AND (TRUNC(pi_dData) BETWEEN NVL(DTINICIO, TRUNC(pi_dData)) AND NVL(DTFIM, TRUNC(pi_dData)))
        UNION   
        SELECT 5 PRIORIDADE,
               'RR' TIPOCOMISSAOMED,
               DECODE(NVL(TIPOVENDEDOR,'N'),'S', DECODE(pi_vTipoVend, 'I', NVL(PERCOMINT,0),
                                                                      'E', NVL(PERCOMEXT,0),
                                                                      'R', NVL(PERCOM,0)),
                                            PCCOMISSAOREGIAO.PERCOM) PERCOM
          FROM PCCOMISSAOREGIAO
         WHERE ((NUMREGIAO IS NULL) OR (NUMREGIAO = pi_nNumRegiao))
           AND (ROUND(NVL(pi_nPerDesc,0),2) BETWEEN PERDESCINI AND PERDESCFIM)
           AND (NVL(TIPO,'R') = 'R') -->> POR REGIAO
           AND ((CODFILIAL IS NULL) OR (NVL(CODFILIAL,' ') = pi_vCodFilial))
           AND (TRUNC(pi_dData) BETWEEN NVL(DTINICIO, TRUNC(pi_dData)) AND NVL(DTFIM, TRUNC(pi_dData)))
         ORDER BY 1; -->> Ordenado pela Prioridade, ao achar o primeiro irá sair do Laço    
    BEGIN
    
      -- Pesquisa a Comissão por Região e Produto
      FOR vc_ComissRegProd IN c_ComissRegProd(pi_vTipoVend,
                                              pi_vCodFilial,
                                              pi_nNumRegiao,
                                              pi_dData,
                                              pi_nCodProd,
                                              pi_nCodLinhaProd,
                                              pi_nCodepto,
                                              pi_nCodSec,
                                              pi_nPerDesc) LOOP
                                              
        IF (vc_ComissRegProd.PERCOM IS NOT NULL) THEN
  
          IF (NVL(vc_ComissRegProd.PERCOM,0) = 0) THEN
            IF (NVL(pi_vConsiderarComissaoZero,'N') = 'S') THEN
              pio_nPerCom       := NVL(vc_ComissRegProd.PERCOM,0); 
              vvTipoComissaoMed := vc_ComissRegProd.TIPOCOMISSAOMED;
            END IF;
          ELSE
            pio_nPerCom       := NVL(vc_ComissRegProd.PERCOM,0); 
            vvTipoComissaoMed := vc_ComissRegProd.TIPOCOMISSAOMED;
          END IF;
        
        END IF;                                             
                                              
        -- Sai após achar o primeiro
        EXIT;
                                                    
      END LOOP; -- Fim Região e Produto
    
    END P_COMISSAO_REGIAO;
  
    --------------------------------------------------------------
    -- PROCEDURE: P_COMISSAO_POLITICA
    -- DESCRIÇÃO: Obter Comissão informada na Politica de Desconto 
    --------------------------------------------------------------
    PROCEDURE P_COMISSAO_POLITICA(pi_vConsiderarComissaoZero IN VARCHAR2,
                                  pi_vTipoVend               IN VARCHAR2,                           
                                  pi_nCodDesconto            IN NUMBER,
                                  pi_nCodPromocaoMed         IN NUMBER,
                                  pio_nPerCom                IN OUT NUMBER)
    IS
  
      -- Cursor de Comissão da Politica de Desconto
      CURSOR c_ComissaoPolitica(pi_vTipoVend    IN VARCHAR2,                           
                                pi_nCodDesconto IN NUMBER) IS
  
        SELECT DECODE(pi_vTipoVend
                     ,'I', PERCOMMINT
                     ,'E', PERCOMEXT
                     ,'R', PERCOMREP
                     ,0) PERCOM
          FROM PCDESCONTO
         WHERE (PCDESCONTO.CODDESCONTO = pi_nCodDesconto);
  
      -- Cursor de Comissão do LOG Politica de Desconto 
      CURSOR c_ComissaoLogPolitica(pi_vTipoVend       IN VARCHAR2,                           
                                   pi_nCodDesconto    IN NUMBER,
                                   pi_nCodPromocaoMed IN NUMBER) IS
  
        SELECT DECODE(pi_vTipoVend
                     ,'I', PERCOMMINT
                     ,'E', PERCOMEXT
                     ,'R', PERCOMREP
                     ,0) PERCOM
          FROM PCDESCONTOLOG
         WHERE (PCDESCONTOLOG.CODDESCONTO = pi_nCodDesconto)
           AND ( (NVL(pi_nCodPromocaoMed,0) = 0) OR 
                 ((NVL(pi_nCodPromocaoMed,0) <> 0) AND (NVL(PCDESCONTOLOG.CODPROMOCAOMED,0) = NVL(pi_nCodPromocaoMed,0))) );
      
    BEGIN
    
      -- Pesquisa a Comissão da Política
      FOR vc_ComissaoPolitica IN c_ComissaoPolitica(pi_vTipoVend,
                                                    pi_nCodDesconto) LOOP
                                              
        IF (vc_ComissaoPolitica.PERCOM IS NOT NULL) THEN
  
          IF (NVL(vc_ComissaoPolitica.PERCOM,0) = 0) THEN
            IF (NVL(pi_vConsiderarComissaoZero,'N') = 'S') THEN
              pio_nPerCom       := NVL(vc_ComissaoPolitica.PERCOM,0); 
              vvTipoComissaoMed := 'DS';
            END IF;
          ELSE
            pio_nPerCom       := NVL(vc_ComissaoPolitica.PERCOM,0); 
            vvTipoComissaoMed := 'DS';
          END IF;
        
        END IF;                                             
                                              
        -- Sai após achar o primeiro
        EXIT;
                                                    
      END LOOP;  
      
      -- Se Chamado da Rotina 2308 (Recálculo)
      -- e tem Promoção associado ao Desconto
      -- e não achou na PCDESCONTO
      IF (pi_nTipoChamada    = 2)     AND
         (pi_nCodDesconto    > 0)     AND
         (pi_nCodPromocaoMed > 0)     AND
         (pio_nPerCom        IS NULL) THEN
      
        -- Pesquisa a Comissão do LOG da Política
        FOR vc_ComissaoLogPolitica IN c_ComissaoLogPolitica(pi_vTipoVend,
                                                            pi_nCodDesconto,
                                                            pi_nCodPromocaoMed) LOOP
                                                
          IF (vc_ComissaoLogPolitica.PERCOM IS NOT NULL) THEN
    
            IF (NVL(vc_ComissaoLogPolitica.PERCOM,0) = 0) THEN
              IF (NVL(pi_vConsiderarComissaoZero,'N') = 'S') THEN
                pio_nPerCom      := NVL(vc_ComissaoLogPolitica.PERCOM,0); 
               vvTipoComissaoMed := 'LD';
              END IF;
            ELSE
              pio_nPerCom        := NVL(vc_ComissaoLogPolitica.PERCOM,0); 
               vvTipoComissaoMed := 'LD';
            END IF;
          
          END IF;                                             
                                                
          -- Sai após achar o primeiro
          EXIT;
                                                      
        END LOOP;  
      
      END IF;                                                                               
    
    END P_COMISSAO_POLITICA;
  
  /*******************************************************************************
                     INICIO DO PROCESSAMENTO PRINCIPAL
   *******************************************************************************/
  BEGIN
  
   /**************************
    Inicialização dos Retornos
    **************************/
    
    po_nPerCom         := 0;
    po_vOcorreramErros := 'N';
    po_vMsgErros       := NULL;
    
   /***********************************
    Restrição de Pesquisa das Comissões
    ***********************************/
    
    -- Pesquisa por padrão Todas as Comissões
    vbTodasComissoes := TRUE;
    -- Pega o Tipo de Comissão do Parâmetro
    vvTipoComissao   := NVL(pi_vTipoComissao,'T');
    -- Restrições
    IF (vvTipoComissao = 'RA') THEN
      vbTodasComissoes := FALSE;
    END IF; 
  
   /**************************************************************
    Inicialização de Variáveis para uso nos procedimentos internos
    **************************************************************/
    
    -- Pesquisa Parâmetros
    BEGIN
      SELECT PCCONSUM.USACOMISSAOPORRCA
           , PCCONSUM.COMISSAORCATIPOVENDA
           , PCCONSUM.USACOMISSAOPORCLIENTE
        INTO vrParametros.vUSACOMISSAOPORRCA
           , vrParametros.vCOMISSAORCATIPOVENDA
           , vrParametros.vUSACOMISSAOPORCLIENTE
        FROM PCCONSUM;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vrParametros.vUSACOMISSAOPORRCA     := 'N';
        vrParametros.vCOMISSAORCATIPOVENDA  := 'N';
        vrParametros.vUSACOMISSAOPORCLIENTE := 'N';
    END;  
  
    -- Pesquisa Dados da Filial
    BEGIN
      SELECT PCFILIAL.CONSIDERARCOMISSAOZERO
           , TIPOAVALIACAOCOMISSAO
        INTO vrParametros.vCONSIDERARCOMISSAOZERO
           , vrParametros.nTIPOAVALIACAOCOMISSAO
        FROM PCFILIAL
       WHERE (PCFILIAL.CODIGO = pi_vCodFilial);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vrParametros.vCONSIDERARCOMISSAOZERO := 'N';
        vrParametros.nTIPOAVALIACAOCOMISSAO  := NULL;
    END;  
    
    -- Pesquisa Dados do Plano de Pagamento
    BEGIN
      SELECT PCPLPAG.TIPOVENDA
        INTO vrPlPag.vTIPOVENDA
        FROM PCPLPAG
       WHERE (PCPLPAG.CODPLPAG = pi_nCodPlPag);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vrPlPag.vTIPOVENDA := NULL;
    END;  
    
    -- Pesquisa Dados do RCA
    BEGIN
      SELECT PCUSUARI.TIPOVEND
           , PCUSUARI.PERCENT
           , PCUSUARI.PERCENT2
        INTO vrRca.vTIPOVEND
           , vrRca.nPERCENT
           , vrRca.nPERCENT2
        FROM PCUSUARI
       WHERE (PCUSUARI.CODUSUR = pi_nCodUsur);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vrRca.vTIPOVEND := NULL;
        vrRca.nPERCENT  := 0;
        vrRca.nPERCENT2 := 0;
    END;  
    
    -- Pesquisa Dados do Cliente
    BEGIN
      SELECT PCCLIENT.CODATV1
        INTO vrCliente.nCODATV1
        FROM PCCLIENT
       WHERE (PCCLIENT.CODCLI = pi_nCodCli);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vrCliente.nCODATV1 := NULL;
    END;  
    
   /*****************
    Ordem da Comissão
    *****************/
    IF    (NVL(vrParametros.nTIPOAVALIACAOCOMISSAO,1) = 1) THEN
      vtOrdemComissao(1) := 'PRO';
      vtOrdemComissao(2) := 'RAM';
      vtOrdemComissao(3) := 'CLI';
      vtOrdemComissao(4) := 'RCA';
      vtOrdemComissao(5) := 'USU'; -- HIS.00665.2017
      vtOrdemComissao(6) := 'REG';
      vtOrdemComissao(7) := 'POL';
    --ELSIF (NVL(vrParametros.nTIPOAVALIACAOCOMISSAO,1) = 2) THEN
    ELSE
      viIdxOrigemComissao := 1;
      FOR vcOrdem IN (SELECT CODCOMIS, 
                             ORDEM,
                             CASE
                               WHEN CODCOMIS = 1  THEN
                                 'PRO'
                               WHEN CODCOMIS = 2  THEN
                                 'CLI'
                               WHEN CODCOMIS = 3  THEN
                                 'RCA'
                               WHEN CODCOMIS = 6  THEN -- HIS.00665.2017
                                 'USU'
                               WHEN CODCOMIS = 8  THEN
                                 'REG'
                               WHEN CODCOMIS = 10 THEN
                                 'POL'
                             END TIPO
                        FROM PCORDEMAPURACAOCOMIS
                       WHERE (CODFILIAL = pi_vCodFilial)
                         AND (CODCOMIS IN (1,2,3,6,8,10))
                      ORDER BY ORDEM) LOOP
        -- Tipo Adicional
        IF (vcOrdem.TIPO = 'CLI') THEN
          vtOrdemComissao(viIdxOrigemComissao) := 'RAM';
          viIdxOrigemComissao := NVL(viIdxOrigemComissao,0) + 1;
        END IF;
        -- Tipo do Laço do Cursor
        vtOrdemComissao(viIdxOrigemComissao) := vcOrdem.TIPO;
        viIdxOrigemComissao := NVL(viIdxOrigemComissao,0) + 1;
      END LOOP;                    
    END IF;
  
    -----------------------------------------------------------------------------
    --                  COMISSÃO DIFERENCIADA FARMA/HOSPITALAR                 --
    -----------------------------------------------------------------------------
    IF (NVL(pi_nTipoChamada,0) = 3) THEN
    
      -- Pesquisa a Linha do Produto
      BEGIN
        SELECT CODLINHAPROD
             , CODEPTO
             , CODSEC        
          INTO vrProd.nCODLINHAPROD
             , vrProd.nCODEPTO
             , vrProd.nCODSEC        
          FROM PCPRODUT
         WHERE (CODPROD = pi_nCodProd);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vrProd.nCODLINHAPROD := NULL;
          vrProd.nCODEPTO      := NULL;
          vrProd.nCODSEC       := NULL;   
      END;
    
      -- Pesquisa a Comissão diferenciada
      -->> RCA
      IF   (pi_nTipoDefinicaoComiss = 1) THEN
        P_COMISSAO_REGIAOMED(vrParametros.vCONSIDERARCOMISSAOZERO,
                             vrRca.vTIPOVEND,
                             pi_vCodFilial,
                             pi_nNumRegiao,
                             pi_dData,
                             vrProd.nCODLINHAPROD,
                             vrProd.nCODEPTO,
                             vrProd.nCODSEC,
                             pi_nPerDesc,
                             po_nPerCom);
      -->> RCA 2 que não precisa ser o Emitente
      ELSIF (pi_nTipoDefinicaoComiss = 3) THEN
        P_COMISSAO_REGIAOMED(vrParametros.vCONSIDERARCOMISSAOZERO,
                             vrRca.vTIPOVEND,
                             pi_vCodFilial,
                             pi_nNumRegiao,
                             pi_dData,
                             vrProd.nCODLINHAPROD,
                             vrProd.nCODEPTO,
                             vrProd.nCODSEC,
                             pi_nPerDesc,
                             po_nPerCom);
     END IF;                           
    
    -----------------------------------------------------------------------------
    --                  COMISSÃO CONFORME ORDEM DAS COMISSÕES                  --
    -----------------------------------------------------------------------------
    ELSE
    
      -- Verifica se Prioriza Comissão - MED-2595
      BEGIN
        SELECT PRIORIZACOMISSAO
          INTO vPriorizaComissao
          FROM PCPROMOCAOMED
         WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vPriorizaComissao := 'N';
      END;
      
      -- Se Prioriza Comissão E não for Recálculo de comissão
      IF (NVL(vPriorizaComissao,'N') = 'S') AND
         (NVL(pi_nTipoChamada,0) <> 2)      THEN
      
        -- Busca Comissão da Promoção
        po_nPerCom := F_OBTER_COMISSAO_PROMOCAO(pi_nCodDesconto,
                                                pi_nCodPromocaoMed,
                                                vrRca.vTIPOVEND,
                                                pi_nCodProd);
        vvTipoComissaoMed := 'DS';
      
      ELSE                                     
                                        
        IF (vtOrdemComissao.COUNT > 0) THEN
          FOR viIdxOrigemComissao IN vtOrdemComissao.FIRST..vtOrdemComissao.LAST LOOP 
      
           /*******************************
            Obter Comissão informada no RCA
            *******************************/
            IF (vtOrdemComissao(viIdxOrigemComissao) = 'RCA') THEN
              IF (vbTodasComissoes) THEN
                P_COMISSAO_RCA(vrParametros.vUSACOMISSAOPORRCA,
                               vrParametros.vCOMISSAORCATIPOVENDA,
                               vrParametros.vCONSIDERARCOMISSAOZERO,
                               vrPlPag.vTIPOVENDA,
                               vrRca.nPERCENT,
                               vrRca.nPERCENT2,
                               pi_nCodEdital,
                               pi_nCodUsur,
                               po_nPerCom);
              END IF;                   
            END IF;                   
          
           /*******************************************
            Obter Comissão informada por Ramo Atividade
            *******************************************/
            IF (vtOrdemComissao(viIdxOrigemComissao) = 'RAM') THEN
              IF (vbTodasComissoes) OR
                 ((NOT vbTodasComissoes) AND (vvTipoComissao = 'RA')) THEN
                P_COMISSAO_RAMO_ATIVIDADE(vrParametros.vCONSIDERARCOMISSAOZERO,
                                          vrRca.vTIPOVEND,
                                          pi_nCodCli,
                                          vrCliente.nCODATV1,
                                          po_nPerCom);
              END IF;                   
            END IF;                   
                           
           /************************************
            Obter Comissão informada por Cliente
            ************************************/
            IF (vtOrdemComissao(viIdxOrigemComissao) = 'CLI') THEN
              IF (vbTodasComissoes) THEN
                P_COMISSAO_CLIENTE(vrParametros.vUSACOMISSAOPORCLIENTE,
                                   vrParametros.vCONSIDERARCOMISSAOZERO,
                                   vrRca.vTIPOVEND,
                                   pi_nCodCli,
                                   po_nPerCom);
              END IF;                   
            END IF;                   
          
           /************************************************************
            Obter Comissão informada por Desconto e RCA - HIS.00665.2017
            ************************************************************/
            IF (vtOrdemComissao(viIdxOrigemComissao) = 'USU') THEN
              IF (vbTodasComissoes) THEN
              
                -- Pesquisa Depto. e Seção do Produto
                BEGIN
                  SELECT CODEPTO
                       , CODSEC        
                    INTO vrProd.nCODEPTO
                       , vrProd.nCODSEC        
                    FROM PCPRODUT
                   WHERE (CODPROD = pi_nCodProd);
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    vrProd.nCODEPTO := NULL;
                    vrProd.nCODSEC  := NULL;   
                END;
              
                -- Pesquisa a Comissão
                P_COMISSAO_USUR(vrParametros.vCONSIDERARCOMISSAOZERO,
                                pi_nCodUsur,
                                pi_nCodProd,
                                vrProd.nCODEPTO,
                                vrProd.nCODSEC,
                                pi_nPerDesc,
                                po_nPerCom);
              END IF;                   
            END IF; 
                  
           /***********************************
            Obter Comissão informada por Região
            ***********************************/
            IF (vtOrdemComissao(viIdxOrigemComissao) = 'REG') THEN
              IF (vbTodasComissoes) THEN
              
                -- Pesquisa a Linha do Produto
                BEGIN
                  SELECT CODLINHAPROD
                       , CODEPTO
                       , CODSEC        
                    INTO vrProd.nCODLINHAPROD
                       , vrProd.nCODEPTO
                       , vrProd.nCODSEC        
                    FROM PCPRODUT
                   WHERE (CODPROD = pi_nCodProd);
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    vrProd.nCODLINHAPROD := NULL;
                    vrProd.nCODEPTO      := NULL;
                    vrProd.nCODSEC       := NULL;   
                END;
              
                -- Pesquisa a Comissão
                P_COMISSAO_REGIAO(vrParametros.vCONSIDERARCOMISSAOZERO,
                                  vrRca.vTIPOVEND,
                                  pi_vCodFilial,
                                  pi_nNumRegiao,
                                  pi_dData,
                                  pi_nCodProd,
                                  vrProd.nCODLINHAPROD,
                                  vrProd.nCODEPTO,
                                  vrProd.nCODSEC,
                                  pi_nPerDesc,
                                  po_nPerCom);
              END IF;                   
            END IF;                   
          
           /************************************
            Obter Comissão informada por Produto
            ************************************/
            IF (vtOrdemComissao(viIdxOrigemComissao) = 'PRO') THEN
              IF (vbTodasComissoes) THEN
                P_COMISSAO_PRODUTO(vrParametros.vCONSIDERARCOMISSAOZERO,
                                   vrRca.vTIPOVEND,
                                   pi_dData,
                                   pi_nCodProd,
                                   pi_vCodFilial,
                                   pi_nPerDesc,
                                   po_nPerCom);
              END IF;                   
            END IF;                   
          
           /*************************************************
            Obter Comissão informada na Política de Descontos
            *************************************************/
            IF (vtOrdemComissao(viIdxOrigemComissao) = 'POL') THEN
              IF (vbTodasComissoes) THEN
                P_COMISSAO_POLITICA(vrParametros.vCONSIDERARCOMISSAOZERO,
                                    vrRca.vTIPOVEND,                    
                                    pi_nCodDesconto,
                                    pi_nCodPromocaoMed,
                                    po_nPerCom);
              END IF;                 
            END IF;                 
            
          END LOOP;
        END IF; -- FIM ORDEM DAS COMISSÕES      
        
      END IF; -- Fim Condição: Prioriza Comissão
      
    END IF; -- FIM CONDIÇÃO: COMISSÃO DIFERENCIADA FARMA/HOSPITALAR ou COMISSÃO CONFORME ORDEM DAS COMISSÕES               
                        
   /********************************************************
    Regra de Comissão do Operador:
    Somente tem Comissão se o próprio Funcionário for o RCA2
    passado no Parâmetro como pi_nCodUsur
    ********************************************************/
    IF (pi_nTipoDefinicaoComiss = 2) THEN                      
    
      -- Pesquisa RCA do Funcionário
      BEGIN
        SELECT PCEMPR.CODUSUR
          INTO vrEmpr.nCODUSUR
          FROM PCEMPR
         WHERE (PCEMPR.MATRICULA = pi_nMatricula);           
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vrEmpr.nCODUSUR := NULL;
      END;
      
      -- Se o Emitente não for um Televendas, zera a Comissão
      -- (Operador não tem Código de RCA, operador não concede comissão ao RCA2, 
      --  se o Digitador for outro Televendas aí pode considerar a comissão do RCA2 - 31/03/2016)
      IF (NVL(vrEmpr.nCODUSUR,0) = 0) THEN
        po_nPerCom        := 0;
        vvTipoComissaoMed := 'ZT';
      END IF;
    
    END IF;
    
    -- Se chamado da Validação da Promoção, retorna o Tipo de Promoção
    IF (pi_nTipoChamada IN (2,4)) THEN
      IF (pi_vOrigemPed = 'F')   AND 
         (pi_vTipoFv    IS NULL) THEN
        po_vMsgErros := 'F' || NVL(vvTipoComissaoMed,' ');
      ELSE
        po_vMsgErros := 'T' || NVL(vvTipoComissaoMed,' ');
      END IF;
    END IF; -- Fim Condição: Se chamado da Validação da Promoção
  
  EXCEPTION
    WHEN e_Tratado THEN
      po_nPerCom   := 0;
      po_vMsgErros := 'S';
      po_vMsgErros := vvMsgErroTratado;
    WHEN OTHERS THEN
      po_nPerCom   := 0;
      po_vMsgErros := 'S';
      po_vMsgErros := 'Erro Cálculo Comissão: ' || SUBSTR('Erro: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ' >> ' || SQLERRM,1,240);
  END P_OBTER_COMISSAO;

 /**********************************************************************************************
  OBJETO...: P_OBTER_DIAS_PRAZO_PEDIDO
  DESCRIÇÃO: Procedure para retornar os dias de Prazo de 1 a 12 do Plano de Pagamento
             DDMEDICA-570
  OBS......: Parâmetros: pi_nItensEticos, pi_nItensGenericos e pi_dDtVencCustomizado são de uso
             de testes automatizados que não requerem pedido para validação
  **********************************************************************************************/  
  PROCEDURE P_OBTER_DIAS_PRAZO_PEDIDO(pi_vCarregarTabTemp   IN VARCHAR2,
                                      pi_nCodPlPag          IN NUMBER,
                                      pi_nCodPlPagEtico     IN NUMBER,
                                      pi_nCodPlPagGenerico  IN NUMBER,
                                      pi_dDtEntrega         IN DATE,
                                      pi_nNumPed            IN NUMBER,
                                      pi_nCondVenda         IN NUMBER,
                                      pi_vOrigemPed         IN VARCHAR2,
                                      pi_vTipoFv            IN VARCHAR2,
                                      pi_vTipoPrazoMedicam  IN VARCHAR2,
                                      pi_nValorEticos       IN NUMBER,
                                      pi_nValorGenericos    IN NUMBER,                                      pi_dDtVencCustomizado IN DATE,
                                      po_vCalculouPrazos   OUT VARCHAR2,
                                      po_nQtdePrazosCalc   OUT NUMBER,
                                      po_nPrazo1           OUT NUMBER,
                                      po_nPrazo2           OUT NUMBER,
                                      po_nPrazo3           OUT NUMBER,
                                      po_nPrazo4           OUT NUMBER,
                                      po_nPrazo5           OUT NUMBER,
                                      po_nPrazo6           OUT NUMBER,
                                      po_nPrazo7           OUT NUMBER,
                                      po_nPrazo8           OUT NUMBER,
                                      po_nPrazo9           OUT NUMBER,
                                      po_nPrazo10          OUT NUMBER,
                                      po_nPrazo11          OUT NUMBER,
                                      po_nPrazo12          OUT NUMBER,
                                      po_nPrazoMedio       OUT NUMBER,
                                      pi_vUsarPrazoCustom   IN VARCHAR2 DEFAULT 'N',
                                      pi_nPrazoCustom1      IN NUMBER DEFAULT NULL,
                                      pi_nPrazoCustom2      IN NUMBER DEFAULT NULL,
                                      pi_nPrazoCustom3      IN NUMBER DEFAULT NULL,
                                      pi_nPrazoCustom4      IN NUMBER DEFAULT NULL,
                                      pi_nPrazoCustom5      IN NUMBER DEFAULT NULL,
                                      pi_nPrazoCustom6      IN NUMBER DEFAULT NULL,
                                      pi_nPrazoCustom7      IN NUMBER DEFAULT NULL,
                                      pi_nPrazoCustom8      IN NUMBER DEFAULT NULL,
                                      pi_nPrazoCustom9      IN NUMBER DEFAULT NULL,
                                      pi_nPrazoCustom10     IN NUMBER DEFAULT NULL,
                                      pi_nPrazoCustom11     IN NUMBER DEFAULT NULL,
                                      pi_nPrazoCustom12     IN NUMBER DEFAULT NULL) IS
                                  
    -- Array de Parcelas
    TYPE TTArrayParcelas IS TABLE OF PCPLPAG.PRAZO1%TYPE INDEX BY BINARY_INTEGER;
    vtArrayParcelas      TTArrayParcelas;
    -- Outras Variáveis
    vnValorEticos          NUMBER;
    vnValorGenericos       NUMBER;
    vnValorTotalNormal     NUMBER;
    vnValorTotalBonificado NUMBER;
    viQtdeParcelas         INTEGER;
    viSomaDiasParcelas     INTEGER;
    viPrazoMedio           INTEGER;
    vvSqlPrazoEtiGen       VARCHAR2(32000);
    vnAuxTotal             NUMBER;
    vnDifParcela           NUMBER;
    viMaiorPrazoEtico      INTEGER;
    viMaiorPrazoGenerico   INTEGER;
    viMaiorPrazo           INTEGER;
                                    
   /*---------------------------------------------------------------------
    PROCEDURE  : atualizar_prazos_datavenc_fixa
    ---------------------------------------------------------------------*/
    PROCEDURE atualizar_prazos_datavenc_fixa(pi_dDtEntrega IN PCNFSAID.DTENTREGA%TYPE,
                                             pi_dDtVenc1   IN PCPLPAG.DTVENC1%TYPE,
                                             pi_dDtVenc2   IN PCPLPAG.DTVENC2%TYPE,
                                             pi_dDtVenc3   IN PCPLPAG.DTVENC3%TYPE,
                                             pio_nPrazo1   IN OUT PCPLPAG.PRAZO1%TYPE,
                                             pio_nPrazo2   IN OUT PCPLPAG.PRAZO2%TYPE,
                                             pio_nPrazo3   IN OUT PCPLPAG.PRAZO3%TYPE) IS
    BEGIN
  
      IF (pi_dDtVenc1 IS NOT NULL) THEN
  
        -- Prazo 1
        pio_nPrazo1 := (pi_dDtVenc1 - pi_dDtEntrega);
        IF (pio_nPrazo1 < 0) THEN
          pio_nPrazo1 := 0;
        END IF;
  
        IF (pi_dDtVenc2 IS NOT NULL) THEN
  
          -- Prazo 2
          pio_nPrazo2 := (pi_dDtVenc2 - pi_dDtEntrega);
          IF (pio_nPrazo2 < 0) THEN
            pio_nPrazo2 := 0;
          END IF;
  
          IF (pi_dDtVenc3 IS NOT NULL) THEN
  
            -- Prazo 3
            pio_nPrazo3 := (pi_dDtVenc3 - pi_dDtEntrega);
            IF (pio_nPrazo3 < 0) THEN
              pio_nPrazo3 := 0;
            END IF;
  
          END IF;
  
        END IF;
  
      END IF;
    END atualizar_prazos_datavenc_fixa;
                                    
   /*--------------------------------------------------------------------
    PROCEDIMENTO : P_CARREGAR_ARRAY_PARCELAS
    --------------------------------------------------------------------*/
    PROCEDURE P_CARREGAR_ARRAY_PARCELAS(pi_bEticoGenerico IN  BOOLEAN,
                                        pi_nCodPlPag      IN  NUMBER,
                                        pi_dDtEntrega     IN  DATE,
                                        po_aArrayParcelas OUT TTArrayParcelas) IS
  
      -- Array para Armazenar os Dados do Plano de Pagamento
      TYPE TRecDadosPlPag IS RECORD(
           vnCodPlPag PCPLPAG.CODPLPAG%TYPE,
           vnPrazo1   PCPLPAG.PRAZO1%TYPE,
           vnPrazo2   PCPLPAG.PRAZO2%TYPE,
           vnPrazo3   PCPLPAG.PRAZO3%TYPE,
           vnPrazo4   PCPLPAG.PRAZO4%TYPE,
           vnPrazo5   PCPLPAG.PRAZO5%TYPE,
           vnPrazo6   PCPLPAG.PRAZO6%TYPE,
           vnPrazo7   PCPLPAG.PRAZO7%TYPE,
           vnPrazo8   PCPLPAG.PRAZO8%TYPE,
           vnPrazo9   PCPLPAG.PRAZO9%TYPE,
           vnPrazo10  PCPLPAG.PRAZO10%TYPE,
           vnPrazo11  PCPLPAG.PRAZO11%TYPE,
           vnPrazo12  PCPLPAG.PRAZO12%TYPE,
           vdDtVenc1  PCPLPAG.DTVENC1%TYPE,
           vdDtVenc2  PCPLPAG.DTVENC2%TYPE,
           vdDtVenc3  PCPLPAG.DTVENC3%TYPE,
           vvFormaParcelamento PCPLPAG.FORMAPARCELAMENTO%TYPE
           );
      vrDadosPlPag    TRecDadosPlPag;
  
      -- Contador de Vencimentos
      viContaVencVariavel INTEGER;
  
      -- Record para armazenar dados do Plano Dia Fixo - 4663.107370.2018
      TYPE TRecDadosPlPagDiaFixo IS RECORD(
           carencia    PCPLPAG.diascarencia%TYPE,
           diafixo     PCPLPAG.diafixo%TYPE,
           numparcelas PCPLPAG.numeroparcelasdiafixo%TYPE);
      vrDadosPlPagDiaFixo TRecDadosPlPagDiaFixo;
      -- Variáveis para Vencimento da Parcela Dia Fixo - 4663.107370.2018
      viVencDiaFixo          INTEGER;
      vdDtVencParcelaDiaFixo DATE;
  
      -- Record para armazenar dados do Plano Mensal
      TYPE TRecDadosPlPagMensal IS RECORD(
           numdiascarencia  PCPLPAG.diascarencia%TYPE,
           numparcelas      PCPLPAG.numparcelas%TYPE);
      vrDadosPlPagMensal TRecDadosPlPagMensal;
      -- Variáveis para Vencimento da Parcela Dia Fixo - 4663.107370.2018
      viVencMensal          INTEGER;
      vdDtVencParcelaMensal DATE;
	  vb_diavalido boolean;	
    BEGIN
  
      -- Inicializa Retorno
      po_aArrayParcelas.DELETE;
  
      -- Se enviando Plano 99 e não é Ético e Genérico
      IF (NOT pi_bEticoGenerico)              AND 
         (pi_nCodPlPag = 99)                  AND
         (NVL(pi_vUsarPrazoCustom,'N') = 'S') THEN
         
        -- Informações de Prazo Customizado 99 passados no parâmetro
        vrDadosPlPag.vnPrazo1  := pi_nPrazoCustom1;
        vrDadosPlPag.vnPrazo2  := pi_nPrazoCustom2;
        vrDadosPlPag.vnPrazo3  := pi_nPrazoCustom3;
        vrDadosPlPag.vnPrazo4  := pi_nPrazoCustom4;
        vrDadosPlPag.vnPrazo5  := pi_nPrazoCustom5;
        vrDadosPlPag.vnPrazo6  := pi_nPrazoCustom6;
        vrDadosPlPag.vnPrazo7  := pi_nPrazoCustom7;
        vrDadosPlPag.vnPrazo8  := pi_nPrazoCustom8;
        vrDadosPlPag.vnPrazo9  := pi_nPrazoCustom9;
        vrDadosPlPag.vnPrazo10 := pi_nPrazoCustom10;
        vrDadosPlPag.vnPrazo11 := pi_nPrazoCustom11;
        vrDadosPlPag.vnPrazo12 := pi_nPrazoCustom12;
        vrDadosPlPag.vdDtVenc1 := NULL;
        vrDadosPlPag.vdDtVenc2 := NULL;
        vrDadosPlPag.vdDtVenc3 := NULL;
        vrDadosPlPag.vvFormaParcelamento := 'C';
         
      ELSE
      
        -- Pesquisa informações do Plano de Pagamento
        BEGIN
          SELECT PCPLPAG.PRAZO1
               , PCPLPAG.PRAZO2
               , PCPLPAG.PRAZO3
               , PCPLPAG.PRAZO4
               , PCPLPAG.PRAZO5
               , PCPLPAG.PRAZO6
               , PCPLPAG.PRAZO7
               , PCPLPAG.PRAZO8
               , PCPLPAG.PRAZO9
               , PCPLPAG.PRAZO10
               , PCPLPAG.PRAZO11
               , PCPLPAG.PRAZO12
               , PCPLPAG.DTVENC1
               , PCPLPAG.DTVENC2
               , PCPLPAG.DTVENC3
               , PCPLPAG.FORMAPARCELAMENTO
            INTO vrDadosPlPag.vnPrazo1
               , vrDadosPlPag.vnPrazo2
               , vrDadosPlPag.vnPrazo3
               , vrDadosPlPag.vnPrazo4
               , vrDadosPlPag.vnPrazo5
               , vrDadosPlPag.vnPrazo6
               , vrDadosPlPag.vnPrazo7
               , vrDadosPlPag.vnPrazo8
               , vrDadosPlPag.vnPrazo9
               , vrDadosPlPag.vnPrazo10
               , vrDadosPlPag.vnPrazo11
               , vrDadosPlPag.vnPrazo12
               , vrDadosPlPag.vdDtVenc1
               , vrDadosPlPag.vdDtVenc2
               , vrDadosPlPag.vdDtVenc3
               , vrDadosPlPag.vvFormaParcelamento
            FROM PCPLPAG
           WHERE (PCPLPAG.CODPLPAG = pi_nCodPlPag);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vrDadosPlPag.vnPrazo1  := NULL;
            vrDadosPlPag.vnPrazo2  := NULL;
            vrDadosPlPag.vnPrazo3  := NULL;
            vrDadosPlPag.vnPrazo4  := NULL;
            vrDadosPlPag.vnPrazo5  := NULL;
            vrDadosPlPag.vnPrazo6  := NULL;
            vrDadosPlPag.vnPrazo7  := NULL;
            vrDadosPlPag.vnPrazo8  := NULL;
            vrDadosPlPag.vnPrazo9  := NULL;
            vrDadosPlPag.vnPrazo10 := NULL;
            vrDadosPlPag.vnPrazo11 := NULL;
            vrDadosPlPag.vnPrazo12 := NULL;
            vrDadosPlPag.vdDtVenc1 := NULL;
            vrDadosPlPag.vdDtVenc2 := NULL;
            vrDadosPlPag.vdDtVenc3 := NULL;
            vrDadosPlPag.vvFormaParcelamento := NULL;
        END;
        
      END IF;
  
      -- Contador de Vencimentos Variáveis
      viContaVencVariavel := 0;
  
      -- ORIGEM = DATAS DE VENCIMENTO INFORMADAS NO PEDIDO ----------------------------------------
      IF (NVL(vrDadosPlPag.vvFormaParcelamento,'C') = 'V') THEN
  
        -- Preeche Arrray a partir dos vencimentos pré-informados
        IF (NVL(pi_nNumPed,0) > 0) THEN
          FOR vc_VencVariavel IN (SELECT (PCPEDCVCTO.DTVENC - TRUNC(pi_dDtEntrega)) PRAZO
                                    FROM PCPEDCVCTO
                                   WHERE (PCPEDCVCTO.NUMPED = pi_nNumPed)-->> Depois de Faturar
                                   ORDER BY 1 -- PRAZO
                                  ) LOOP
            viContaVencVariavel := NVL(viContaVencVariavel,0) + 1;
            po_aArrayParcelas(viContaVencVariavel) := NVL(vc_VencVariavel.PRAZO,0);
          END LOOP;
        ELSE 
          -- Para vencimento customizado único
          IF (pi_dDtVencCustomizado IS NOT NULL) THEN
            IF (pi_dDtVencCustomizado >= pi_dDtEntrega) THEN
              FOR vc_VencVariavel IN (SELECT (pi_dDtVencCustomizado - TRUNC(pi_dDtEntrega)) PRAZO
                                        FROM DUAL
                                      ) LOOP
                viContaVencVariavel := NVL(viContaVencVariavel,0) + 1;
                po_aArrayParcelas(viContaVencVariavel) := NVL(vc_VencVariavel.PRAZO,0);
              END LOOP;
            END IF;
          END IF;
        END IF;
  
      -- 4663.107370.2018 - Implementação Regra Data Fixa
      ELSIF (vrDadosPlPag.vvFormaParcelamento = 'T') THEN
  
        BEGIN
          SELECT NVL(pcplpag.diascarencia, 0),
                 NVL(pcplpag.diafixo, 1),
                 NVL(pcplpag.numeroparcelasdiafixo, 1)
            INTO vrDadosPlPagDiaFixo.carencia,
                 vrDadosPlPagDiaFixo.diafixo,
                 vrDadosPlPagDiaFixo.numparcelas
            FROM pcplpag
           WHERE (pcplpag.codplpag = pi_nCodPlPag);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vrDadosPlPagDiaFixo.carencia    := NULL;
            vrDadosPlPagDiaFixo.diafixo     := NULL;
            vrDadosPlPagDiaFixo.numparcelas := NULL;
        END;
  
        -- Se Calcula Parcelas Dia Fixo
        IF (NVL(vrDadosPlPagDiaFixo.numparcelas,0) > 0) THEN
  
          BEGIN
  
            viVencDiaFixo := 0;
  
            FOR vi IN 1 .. vrDadosPlPagDiaFixo.numparcelas LOOP
                
              vb_diavalido      := FALSE;
              WHILE (NOT vb_diavalido) LOOP
			  -- Se Fevereiro for o mês do Vencimento e no Plano de Pagamento estiver como dia fixo igual ou superior a 29 dias
               IF ((TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE), NVL(viVencDiaFixo,0)),'MM') = '02') AND
                  (NVL(vrDadosPlPagDiaFixo.diafixo,0) >= 29)) THEN
  
                -- Pega o último dia de fevereiro a partir do primeiro dia do próximo mês - 1
                SELECT TO_DATE(TO_CHAR('01') || '/' ||
                               TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE), viVencDiaFixo + 1),
                                       'MM/YYYY'),
                               'DD/MM/YYYY') - 1
                  INTO vdDtVencParcelaDiaFixo
                  FROM DUAL;
  
              -- Se não for Fevereiro
                ELSE
    
                  SELECT TO_DATE(TO_CHAR(vrDadosPlPagDiaFixo.diafixo) || '/' ||
                                 TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE), viVencDiaFixo),
                                         'MM/YYYY'),
                                 'DD/MM/YYYY')
                    INTO vdDtVencParcelaDiaFixo
                    FROM DUAL;
    
                END IF;
              
                IF vi = 1 THEN
                  IF (((TRUNC(SYSDATE) + vrDadosPlPagDiaFixo.carencia)) <= vdDtVencParcelaDiaFixo)  THEN
                    vdDtVencParcelaDiaFixo := ADD_MONTHS(vdDtVencParcelaDiaFixo, 0);
                    viVencDiaFixo          := viVencDiaFixo + 1;
                    vb_diavalido := true;
                  ELSE
                    viVencDiaFixo := viVencDiaFixo + 1;
                  END IF;
              ELSE
                viVencDiaFixo := viVencDiaFixo + 1;
                vb_diavalido := true;
              END IF;

              END LOOP;
  
              viContaVencVariavel := NVL(viContaVencVariavel,0) + 1;
              po_aArrayParcelas(viContaVencVariavel) := (vdDtVencParcelaDiaFixo - TRUNC(SYSDATE));
              IF (po_aArrayParcelas(viContaVencVariavel) < 0) THEN
                po_aArrayParcelas(viContaVencVariavel) := 0;
              END IF;
  
            END LOOP;
  
          EXCEPTION
            WHEN OTHERS THEN
              NULL;
          END;
  
        END IF; -- Fim Condição: Se Calcula Parcelas Dia Fixo
  
      -- 4663.107370.2018 - Implementação Regra Mensal
      ELSIF (vrDadosPlPag.vvFormaParcelamento = 'M') THEN
  
        BEGIN
          SELECT NVL(pcplpag.numdiascarencia, 0),
                 NVL(pcplpag.numparcelas, 1)
            INTO vrDadosPlPagMensal.numdiascarencia,
                 vrDadosPlPagMensal.numparcelas
            FROM pcplpag
           WHERE (pcplpag.codplpag = pi_nCodPlPag);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vrDadosPlPagMensal.numdiascarencia := NULL;
            vrDadosPlPagMensal.numparcelas := NULL;
        END;
  
        -- Se Calcula Parcelas Mensal
        IF (NVL(vrDadosPlPagMensal.numparcelas,0) > 0) THEN
  
          BEGIN
  
            viVencMensal := 0;
  
            FOR vi IN 1 .. vrDadosPlPagMensal.numparcelas LOOP
  
              IF (vi = 1) THEN
                vdDtVencParcelaMensal := (pi_dDtEntrega + NVL(vrDadosPlPagMensal.numdiascarencia,0));
              ELSE
                vdDtVencParcelaMensal := ADD_MONTHS((pi_dDtEntrega + NVL(vrDadosPlPagMensal.numdiascarencia,0)), (vi - 1));
              END IF;
  
              viContaVencVariavel := NVL(viContaVencVariavel,0) + 1;
              po_aArrayParcelas(viContaVencVariavel) := (vdDtVencParcelaMensal - pi_dDtEntrega);
              IF (po_aArrayParcelas(viContaVencVariavel) < 0) THEN
                po_aArrayParcelas(viContaVencVariavel) := 0;
              END IF;
  
            END LOOP;
  
          EXCEPTION
            WHEN OTHERS THEN
              NULL;
          END;
  
        END IF; -- Fim Condição: Se Calcula Parcelas Dia Fixo
  
      END IF; -- FIM CONDIÇÃO: -- Se Vencimemto Variável
  
      -- Se não preencheu os Parcelamentos Variáveis
      IF (NVL(viContaVencVariavel,0) = 0) THEN
  
        -- Se preencheu a Data Vencimento Fixa
        IF (vrDadosPlPag.vdDtVenc1 IS NOT NULL) THEN
  
          atualizar_prazos_datavenc_fixa(pi_dDtEntrega,
                                         vrDadosPlPag.vdDtVenc1,
                                         vrDadosPlPag.vdDtVenc2,
                                         vrDadosPlPag.vdDtVenc3,
                                         vrDadosPlPag.vnPrazo1,
                                         vrDadosPlPag.vnPrazo2,
                                         vrDadosPlPag.vnPrazo3);
  
          po_aArrayParcelas(1) := NVL(vrDadosPlPag.vnPrazo1,0);
          IF (vrDadosPlPag.vdDtVenc2 IS NOT NULL) THEN
            po_aArrayParcelas(2) := NVL(vrDadosPlPag.vnPrazo2,0);
            IF (vrDadosPlPag.vdDtVenc3 IS NOT NULL) THEN
              po_aArrayParcelas(3) := NVL(vrDadosPlPag.vnPrazo3,0);
            END IF;
          END IF;
  
        ELSE
  
          -- Laço de Prazos
          FOR viIdxPrazo IN 1..12 LOOP
  
            -- Pega Prazo
            IF    ((viIdxPrazo = 1)) THEN
              po_aArrayParcelas(viIdxPrazo) := vrDadosPlPag.vnPrazo1;
            ELSIF ((viIdxPrazo = 2) AND (NVL(vrDadosPlPag.vnPrazo2,0) > 0))   THEN
              po_aArrayParcelas(viIdxPrazo) := vrDadosPlPag.vnPrazo2;
            ELSIF ((viIdxPrazo = 3) AND (NVL(vrDadosPlPag.vnPrazo3,0) > 0))   THEN
              po_aArrayParcelas(viIdxPrazo) := vrDadosPlPag.vnPrazo3;
            ELSIF ((viIdxPrazo = 4) AND (NVL(vrDadosPlPag.vnPrazo4,0) > 0))   THEN
              po_aArrayParcelas(viIdxPrazo) := vrDadosPlPag.vnPrazo4;
            ELSIF ((viIdxPrazo = 5) AND (NVL(vrDadosPlPag.vnPrazo5,0) > 0))   THEN
              po_aArrayParcelas(viIdxPrazo) := vrDadosPlPag.vnPrazo5;
            ELSIF ((viIdxPrazo = 6) AND (NVL(vrDadosPlPag.vnPrazo6,0) > 0))   THEN
              po_aArrayParcelas(viIdxPrazo) := vrDadosPlPag.vnPrazo6;
            ELSIF ((viIdxPrazo = 7) AND (NVL(vrDadosPlPag.vnPrazo7,0) > 0))   THEN
              po_aArrayParcelas(viIdxPrazo) := vrDadosPlPag.vnPrazo7;
            ELSIF ((viIdxPrazo = 8) AND (NVL(vrDadosPlPag.vnPrazo8,0) > 0))   THEN
              po_aArrayParcelas(viIdxPrazo) := vrDadosPlPag.vnPrazo8;
            ELSIF ((viIdxPrazo = 9) AND (NVL(vrDadosPlPag.vnPrazo9,0) > 0))   THEN
              po_aArrayParcelas(viIdxPrazo) := vrDadosPlPag.vnPrazo9;
            ELSIF ((viIdxPrazo = 10) AND (NVL(vrDadosPlPag.vnPrazo10,0) > 0)) THEN
              po_aArrayParcelas(viIdxPrazo) := vrDadosPlPag.vnPrazo10;
            ELSIF ((viIdxPrazo = 11) AND (NVL(vrDadosPlPag.vnPrazo11,0) > 0)) THEN
              po_aArrayParcelas(viIdxPrazo) := vrDadosPlPag.vnPrazo11;
            ELSIF ((viIdxPrazo = 12) AND (NVL(vrDadosPlPag.vnPrazo12,0) > 0)) THEN
              po_aArrayParcelas(viIdxPrazo) := vrDadosPlPag.vnPrazo12;
            END IF;
  
          END LOOP; -- Fim Laço de Prazos
  
        END IF; -- Fim Condição Se preencheu a Data Vencimento Fixa
  
      END IF; -- Fim Condição: Se não preencheu os Parcelamentos Variáveis
  
    END P_CARREGAR_ARRAY_PARCELAS;
                                    
    -- INICIO DO PROCESSAMENTO PRINCIPAL --
  BEGIN

    -- Inicializa Retornos
    po_vCalculouPrazos := 'N';
    po_nQtdePrazosCalc := 0;
    po_nPrazo1         := NULL;
    po_nPrazo2         := NULL;
    po_nPrazo3         := NULL;
    po_nPrazo4         := NULL;
    po_nPrazo5         := NULL;
    po_nPrazo6         := NULL;
    po_nPrazo7         := NULL;
    po_nPrazo8         := NULL;
    po_nPrazo9         := NULL;
    po_nPrazo10        := NULL;
    po_nPrazo11        := NULL;
    po_nPrazo12        := NULL;
    po_nPrazoMedio     := NULL;
    
    -- Se apaga Tabela Temporária
    IF (pi_vCarregarTabTemp = 'S') THEN
      DELETE FROM PCMED_TITULOSRECEBER;
    END IF;
    -- Tabela Temporária de Prazos sempre limpa e insere duas linhas vazias para inicializar o grid de parcelas na tela inicial
    DELETE FROM PCMED_PRAZOS_TITULOSRECEBER;
    INSERT INTO PCMED_PRAZOS_TITULOSRECEBER(LINHA) VALUES (1);
    INSERT INTO PCMED_PRAZOS_TITULOSRECEBER(LINHA) VALUES (2);

    IF (NVL(pi_vTipoPrazoMedicam,'N') <> '4') THEN
    
      -- Calculou Prazos                                             
      po_vCalculouPrazos := 'S';
    
      -- Pesquisa Totais do Pedido se passar o Número do Pedido
      IF (NVL(pi_nNumPed,0) > 0) THEN
        SELECT SUM(CASE WHEN NVL(PCPEDI.BONIFIC,'N') = 'N' THEN
                     DECODE(NVL(PCPRODUT.GRUPOFATURAMENTO,'N'),'E',(PCPEDI.PVENDA * PCPEDI.QT),0) 
                   ELSE
                     0
                   END) VALOR_ETICOS
             , SUM(CASE WHEN NVL(PCPEDI.BONIFIC,'N') = 'N' THEN
                     DECODE(NVL(PCPRODUT.GRUPOFATURAMENTO,'N'),'E',0,(PCPEDI.PVENDA * PCPEDI.QT))
                   ELSE
                     0
                   END) VALOR_GENERICOS
             , SUM(CASE WHEN NVL(PCPEDI.BONIFIC,'N') = 'N' THEN
                     (PCPEDI.PVENDA * PCPEDI.QT)
                   ELSE
                     0 
                   END) TOTAL_NORMAL
             , SUM(CASE WHEN (NVL(PCPEDI.BONIFIC,'N') IN ('B','F')) THEN
                     (PCPEDI.PVENDA * PCPEDI.QT)
                   ELSE
                     0 
                   END) TOTAL_BONIFICADO
          INTO vnValorEticos
             , vnValorGenericos
             , vnValorTotalNormal
             , vnValorTotalBonificado
          FROM PCPEDI
             , PCPRODUT
         WHERE (PCPEDI.NUMPED    = pi_nNumPed)
           AND (PCPRODUT.CODPROD = PCPEDI.CODPROD);
      -- Recebe dos parâmetros para teste automatizado
      ELSE
        vnValorEticos          := pi_nValorEticos;
        vnValorGenericos       := pi_nValorGenericos;
        vnValorTotalNormal     := NVL(pi_nValorEticos,0) + NVL(pi_nValorGenericos,0);
        vnValorTotalBonificado := 0;
      END IF;
      
      -- Se for para gravar na Tabela Temporária e não tiver Produtos,
      -- inicializo o Ético e Genérico com valor 1 só pra fazer o cálculo dos dias de Prazo Inicial
      -- e poder sair no grid de parcelas da tela inicial os dias de prazo ao iniciar o pedido
      IF (pi_vCarregarTabTemp = 'N'    ) AND
         (NVL(vnValorTotalNormal,0) = 0) THEN
        vnValorEticos      := 1;
        vnValorGenericos   := 1;
        vnValorTotalNormal := NVL(pi_nValorEticos,0) + NVL(pi_nValorGenericos,0);
      END IF;      
    
      -- Inicializa Array
      vtArrayParcelas.DELETE;

      -----------------------------------
      --  Se Grupo de Faturamento
      -----------------------------------
      IF (NVL(pi_nCodPlPagEtico,0) > 0) AND
         (NVL(pi_nCodPlPagGenerico,0) > 0) THEN
         
        -- Inicializa Texto Sql
        vvSqlPrazoEtiGen     := NULL;
        -- Inicializa maior prazo Ético e Genérico
        viMaiorPrazoEtico    := 0;
        viMaiorPrazoGenerico := 0;
         
        -- Carrega Array de Parcelas do Plano de Pagamento Etico
        IF (NVL(vnValorEticos,0) > 0) THEN
        
          P_CARREGAR_ARRAY_PARCELAS(TRUE,
                                    pi_nCodPlPagEtico, -->> Plano de Pagamento Ético
                                    pi_dDtEntrega,
                                    vtArrayParcelas);
          viQtdeParcelas := NVL(vtArrayParcelas.COUNT,0);                    
          
          -- Se tem Parcelas
          IF (NVL(viQtdeParcelas,0) > 0) THEN
            
            FOR viIdx IN 1..viQtdeParcelas LOOP              
            
              -- Script SQL de Agrupamento
              IF (vvSqlPrazoEtiGen IS NOT NULL) THEN
                vvSqlPrazoEtiGen := vvSqlPrazoEtiGen || ' UNION  ';
              END IF;
              vvSqlPrazoEtiGen := vvSqlPrazoEtiGen || ' SELECT ' || NVL(vtArrayParcelas(viIdx),0) || ' AS PRAZO FROM DUAL ';
              
              -- Guarda maior prazo ético
              viMaiorPrazoEtico := NVL(vtArrayParcelas(viIdx),0);
                
              -- Insere na Tabela Temporária
              IF (pi_vCarregarTabTemp = 'S') THEN
              
                INSERT INTO PCMED_TITULOSRECEBER
                          ( TIPO
                          , PRAZOMED )
                   VALUES ( 'E'
                          , NVL(vtArrayParcelas(viIdx),0) );
              
              END IF;
              
            END LOOP;
            
            -- Atualiza Tabela Temporária
            IF (pi_vCarregarTabTemp = 'S') THEN
            
              UPDATE PCMED_TITULOSRECEBER
                 SET VALORTITULOMED = ROUND(NVL(vnValorEticos,0) / NVL(viQtdeParcelas,0),2)
               WHERE (TIPO = 'E');
            
            END IF;
                        
          END IF; -- FIM: Se tem Parcelas
          
        END IF; -- FIM: Carrega Array de Parcelas do Plano de Pagamento Etico

        -- Carrega Array de Parcelas do Plano de Pagamento Genérico
        IF (NVL(vnValorGenericos,0) > 0) THEN
        
          P_CARREGAR_ARRAY_PARCELAS(TRUE,
                                    pi_nCodPlPagGenerico, -->> Plano de Pagamento Genérico
                                    pi_dDtEntrega,
                                    vtArrayParcelas);
          viQtdeParcelas := NVL(vtArrayParcelas.COUNT,0);
          
          -- Se tem Parcelas
          IF (NVL(viQtdeParcelas,0) > 0) THEN
          
            FOR viIdx IN 1..viQtdeParcelas LOOP
            
              -- Script SQL de Agrupamento
              IF (vvSqlPrazoEtiGen IS NOT NULL) THEN
                vvSqlPrazoEtiGen := vvSqlPrazoEtiGen || ' UNION  ';
              END IF;            
              vvSqlPrazoEtiGen := vvSqlPrazoEtiGen || ' SELECT ' || NVL(vtArrayParcelas(viIdx),0) || ' AS PRAZO FROM DUAL ';

              -- Guarda maior prazo genérico
              viMaiorPrazoGenerico := NVL(vtArrayParcelas(viIdx),0);

              -- Insere na Tabela Temporária
              IF (pi_vCarregarTabTemp = 'S') THEN
              
                INSERT INTO PCMED_TITULOSRECEBER
                          ( TIPO
                          , PRAZOMED )
                   VALUES ( 'G'
                          , NVL(vtArrayParcelas(viIdx),0) );
              
              END IF;
              
            END LOOP;
            
            -- Atualiza Tabela Temporária
            IF (pi_vCarregarTabTemp = 'S') THEN
            
              UPDATE PCMED_TITULOSRECEBER
                 SET VALORTITULOMED = ROUND(NVL(vnValorGenericos,0) / NVL(viQtdeParcelas,0),2)
               WHERE (TIPO = 'G');
            
            END IF;
            
          END IF; -- FIM: Se tem Parcelas
          
        END IF; -- FIM: Carrega Array de Parcelas do Plano de Pagamento Genérico
         
        -- Agrupa Parcelas em Array
        IF (vvSqlPrazoEtiGen IS NOT NULL) THEN

          -- Inicializa Array
          vtArrayParcelas.DELETE;

          -- Finaliza SQL
          vvSqlPrazoEtiGen := ' SELECT PRAZO FROM (' || vvSqlPrazoEtiGen || ') ORDER BY 1';
                    
          -- Insere Dados em Arrays
          EXECUTE IMMEDIATE vvSqlPrazoEtiGen
               BULK COLLECT INTO vtArrayParcelas;
                    
        END IF; -- Fim Condição: Agrupa Parcelas em Array
               
      -----------------------------------
      --  Se NÃO FOR Grupo de Faturamento
      -----------------------------------
      ELSE
                          
        -- Carrega Array de Parcelas do Plano de Pagamento
        P_CARREGAR_ARRAY_PARCELAS(FALSE,
                                  pi_nCodPlPag,
                                  pi_dDtEntrega,
                                  vtArrayParcelas);
        viQtdeParcelas := NVL(vtArrayParcelas.COUNT,0);
        
        IF (NVL(viQtdeParcelas,0) > 0) THEN
        
          FOR viIdx IN 1..viQtdeParcelas LOOP
          
            -- Guarda maior prazo
            viMaiorPrazo := NVL(vtArrayParcelas(viIdx),0);

            -- Insere na Tabela Temporária
            IF (pi_vCarregarTabTemp = 'S') THEN
            
              INSERT INTO PCMED_TITULOSRECEBER
                        ( TIPO
                        , PRAZOMED )
                 VALUES ( 'N'
                        , NVL(vtArrayParcelas(viIdx),0) );
            
            END IF;
            
          END LOOP;
          
          -- Atualiza Tabela Temporária
          IF (pi_vCarregarTabTemp = 'S') THEN
          
            UPDATE PCMED_TITULOSRECEBER
               SET VALORTITULOMED = ROUND(NVL(vnValorTotalNormal,0) / NVL(viQtdeParcelas,0),2)
             WHERE (TIPO = 'N');
          
          END IF;
          
        END IF;
                
      END IF; -- Fim Condição: Se Grupo de Faturamento
      
      -------------------------------------------------------------------------------------------
      -- SE GEROU PARCELAS ----------------------------------------------------------------------
      -------------------------------------------------------------------------------------------
      IF (NVL(vtArrayParcelas.COUNT,0) > 0) THEN
        
        -- Pega a Quantidade de Parcelas do Array
        viQtdeParcelas := NVL(vtArrayParcelas.COUNT,0);

        -- Calcula o Prazo Médio
        viSomaDiasParcelas := 0;
        FOR viIdx IN vtArrayParcelas.FIRST..vtArrayParcelas.LAST LOOP
          viSomaDiasParcelas := NVL(viSomaDiasParcelas,0) + NVL(vtArrayParcelas(viIdx),0);
        END LOOP;     
        IF (viQtdeParcelas > 0) THEN        
          viPrazoMedio := TRUNC(NVL(viSomaDiasParcelas,0) / NVL(viQtdeParcelas,0));
        ELSE 
          viPrazoMedio := 0;
        END IF;    
        
        -- Cria no array as posições das parcelas que não existem até a 12a. Parcela
        FOR viIdx IN (viQtdeParcelas+1)..12 LOOP
          vtArrayParcelas(viIdx) := NULL;
        END LOOP;
        
        -----------------------------------
        -- FINALIZAÇÃO DA TABELA TEMPORÁRIA
        -----------------------------------
        IF (pi_vCarregarTabTemp = 'S') THEN
        
          -- Se não tiver Grupo de Faturamento
          SELECT SUM(VALORTITULOMED)
            INTO vnAuxTotal
            FROM PCMED_TITULOSRECEBER
           WHERE (TIPO IN ('N'));
          IF (NVL(vnAuxTotal,0) > 0) THEN
            -- Ajusta dif. arredondamento
            vnDifParcela := NVL(vnValorTotalNormal,0) - NVL(vnAuxTotal,0);
            UPDATE PCMED_TITULOSRECEBER
               SET VALORTITULOMED = VALORTITULOMED + NVL(vnDifParcela,0)
             WHERE (TIPO = 'N')
               AND (PRAZOMED = viMaiorPrazo);
          END IF;
          
          -- Se tiver Grupo de Faturamento
          SELECT SUM(VALORTITULOMED)
            INTO vnAuxTotal
            FROM PCMED_TITULOSRECEBER
           WHERE (TIPO IN ('E','G'));
          IF (NVL(vnAuxTotal,0) > 0) THEN
            -- Ajusta dif. arredondamento
            vnDifParcela := NVL(vnValorTotalNormal,0) - NVL(vnAuxTotal,0);
            IF (NVL(vnValorEticos,0) > NVL(vnValorGenericos,0)) THEN
              UPDATE PCMED_TITULOSRECEBER
                 SET VALORTITULOMED = VALORTITULOMED + NVL(vnDifParcela,0)
               WHERE (TIPO = 'E')
                 AND (PRAZOMED = viMaiorPrazoEtico);
            ELSE
              UPDATE PCMED_TITULOSRECEBER
                 SET VALORTITULOMED = VALORTITULOMED + NVL(vnDifParcela,0)
               WHERE (TIPO = 'G')
                 AND (PRAZOMED = viMaiorPrazoGenerico);
            END IF;
            -- Agrupa o Ético e Genérico
            INSERT INTO PCMED_TITULOSRECEBER
                      ( TIPO
                      , PRAZOMED
                      , VALORTITULOMED )
                 SELECT 'N' TIPO
                      , PRAZOMED
                      , SUM(VALORTITULOMED)
                   FROM PCMED_TITULOSRECEBER
                  WHERE (TIPO <> 'N')
                  GROUP BY PRAZOMED;          
          END IF;
          
        END IF; -- FIM: FINALIZAÇÃO DA TABELA TEMPORÁRIA

        -----------------------------------
        -- TEMPORÁRIA PARCELA BONIFICADOS
        -----------------------------------
        IF (pi_vCarregarTabTemp = 'S') THEN
        
          IF (pi_nCondVenda = 5) THEN
          
            INSERT INTO PCMED_TITULOSRECEBER
                      ( TIPO
                      , PRAZOMED
                      , VALORTITULOMED )
                VALUES( 'B'
                      , 0
                      , vnValorTotalNormal );
  
          ELSE
        
            IF (vnValorTotalBonificado > 0) THEN
            
              INSERT INTO PCMED_TITULOSRECEBER
                        ( TIPO
                        , PRAZOMED
                        , VALORTITULOMED )
                  VALUES( 'B'
                        , 0
                        , vnValorTotalBonificado );
  
            END IF;
            
          END IF;
          
        END IF;

        -----------------------------------
        -- TABELA TEMPORARIA DE PRAZOS
        -----------------------------------

        -- Limpa
        DELETE FROM PCMED_PRAZOS_TITULOSRECEBER;
        -- Insere
        INSERT INTO PCMED_PRAZOS_TITULOSRECEBER
                   ( LINHA
                   , PARC1
                   , PARC2
                   , PARC3
                   , PARC4
                   , PARC5
                   , PARC6 )
            VALUES ( 1
                   , vtArrayParcelas(1)
                   , vtArrayParcelas(2)
                   , vtArrayParcelas(3)
                   , vtArrayParcelas(4)
                   , vtArrayParcelas(5)
                   , vtArrayParcelas(6) );
        INSERT INTO PCMED_PRAZOS_TITULOSRECEBER
                   ( LINHA
                   , PARC1
                   , PARC2
                   , PARC3
                   , PARC4
                   , PARC5
                   , PARC6 )
            VALUES ( 2
                   , vtArrayParcelas(7)
                   , vtArrayParcelas(8)
                   , vtArrayParcelas(9)
                   , vtArrayParcelas(10)
                   , vtArrayParcelas(11)
                   , vtArrayParcelas(12) );
        
        -----------------------------------
        -- RETORNOS
        -----------------------------------

        -- Calculou Prazos                                             
        po_vCalculouPrazos := 'S';
        po_nQtdePrazosCalc := viQtdeParcelas;
        
        -- Retorna Prazos
        po_nPrazo1     := vtArrayParcelas(1);
        po_nPrazo2     := vtArrayParcelas(2);
        po_nPrazo3     := vtArrayParcelas(3);
        po_nPrazo4     := vtArrayParcelas(4);
        po_nPrazo5     := vtArrayParcelas(5);
        po_nPrazo6     := vtArrayParcelas(6);
        po_nPrazo7     := vtArrayParcelas(7);
        po_nPrazo8     := vtArrayParcelas(8);
        po_nPrazo9     := vtArrayParcelas(9);
        po_nPrazo10    := vtArrayParcelas(10);
        po_nPrazo11    := vtArrayParcelas(11);
        po_nPrazo12    := vtArrayParcelas(12);
        po_nPrazoMedio := viPrazoMedio;
                                                                                                            
      END IF; -- Fim Condição: Se Gerou Prazos
            
    END IF; -- Fim Condição: TipoPrazoMedicamen <> 4
    
  END P_OBTER_DIAS_PRAZO_PEDIDO;   
  
  /*******************************************************************************
   Nome         : P_OBTEM_PMPF
   Descricão    : Procedimento Obter o PMPF dos Medicamentos
   Parâmetros   : ENTRADA:
                  pi_nCodSt   = Código da Tributação
                  pi_nCodProd = Código do Produto
                  pi_nCodCli  = Código do Cliente
                  pi_vEstEnt  = UF do Endereço de Entrega - DDVENDAS-33718
                  SAIDA:
                  po_nPmPf    = PMPF
  **********************************************************************************/                                       
  PROCEDURE P_OBTEM_PMPF(pi_nCodSt   IN  VARCHAR2,
                         pi_nCodProd IN  NUMBER,
                         pi_nCodCli  IN  VARCHAR2,                               
                         po_nPmPf    OUT NUMBER,
                         pi_vEstEnt  IN  VARCHAR2 DEFAULT NULL) IS -- DDVENDAS-33718
    vvUsaPmPfBaseSt PCTRIBUT.USAPMPFBASEST%TYPE;
    vvEstEnt        PCCLIENT.ESTENT%TYPE;
  BEGIN
   
    -- Inicializa Retorno
    po_nPmPf := NULL;
  
    -- Pesquisa Tributação do Produto
    BEGIN
      SELECT PCTRIBUT.USAPMPFBASEST
        INTO vvUsaPmPfBaseSt
        FROM PCTRIBUT
       WHERE (PCTRIBUT.CODST = pi_nCodSt);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vvUsaPmPfBaseSt := 'N';
    END;
    
    -- Se a Tributação Usa PMPF na Base do ST
    IF (vvUsaPmPfBaseSt = 'S') THEN
    
      -- Pesquisa UF do Cliente
      BEGIN
        SELECT ESTENT
          INTO vvEstEnt
          FROM PCCLIENT
         WHERE (CODCLI = pi_nCodCli);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vvEstEnt := NULL;
      END;
      
      -- Pega a UF do Endereço de Entrega recebido no Parâmetro - DDVENDAS-33718
      IF (pi_vEstEnt IS NOT NULL) THEN
        vvEstEnt := pi_vEstEnt;
      END IF;
    
      -- Pesquisa PMPF
      BEGIN
        SELECT PMPF
          INTO po_nPmPf
          FROM PCTABMEDABCFARMA
         WHERE (CODPROD = pi_nCodProd)
           AND (UF      = vvEstEnt);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          po_nPmPf := 0;
      END;
      
    END IF; -- Fim Condição: Se a Tributação Usa PMPF na Base do ST
    
  END P_OBTEM_PMPF;
  
 /*******************************************************************************
  Nome         : F_OBTEM_PRECO_ABCFARMA - DDVENDAS-35697
  Descricão    : Procedimento Obter o Preço ABCFARMA/CMED - Preço Fábrica ou PMC ou Licitação
  Parâmetros   : ENTRADA:
                 pi_vTipoPreco       = 'PF'     - Preço Fábrica
                                       'PMC'    - PMC
                                       'PFLIC'  - Preço Fábrica da Licitação
                                       'PMCLIC' - PMC da Licitação
                 pi_nCodProd         = Código do Produto                
                 pi_vUf              = UF de Destino
                 pi_vCodFilial       = Código da Filial
                 pi_vCodFilialNf     = Código da Filial de Faturamento
                 pi_nCodProd         = Código do Produto
                 pi_nNumRegiao       = Região
                 pi_vTipoCliMed      = Tipo de Cliente Medicamento
                 pi_vConvenioIsencao = S/N
                 SAIDA:
                 po_nPmc             = Valor do PMC
                 po_nPrecoFabrica    = Preço Fábrica
                 po_vMensagem        = Mensagem de Erro
  ********************************************************************************/                                       
  FUNCTION F_OBTEM_PRECO_ABCFARMA(pi_vTipoPreco       IN VARCHAR2,
                                  pi_nCodProd         IN NUMBER,
                                  pi_vUf              IN VARCHAR2,
                                  pi_vCodFilial       IN VARCHAR2,
                                  pi_vCodFilialNf     IN VARCHAR2,
                                  pi_nNumRegiao       IN NUMBER,
                                  pi_vTipoCliMed      IN VARCHAR2,
                                  pi_vConvenioIsencao IN VARCHAR2) RETURN NUMBER
  IS
  
    -- Retorno
    vnRetPreco    PCTABMEDABCFARMA.PRECOFABRICA%TYPE;
    
    -- UF
    vvUf          VARCHAR2(255);
    
    -- Código da Filial
    vvCodFilial   PCFILIAL.CODIGO%TYPE;

    -- UF Exceção
    vvUfExcecao   VARCHAR2(255);
    
    -- Achou Exceção
    vAchouExcecao BOOLEAN;
        
  /*********************************
   INICIO DO PROCESSAMENTO PRINCIPAL  
   *********************************/
  BEGIN

   /******************
    Inicializa Retorno
    ******************/

    vnRetPreco := NULL;

   /********************************************
    Inicializa Variáveis a partir dos Parâmetros
    ********************************************/
    
    vvUf := pi_vUf;
    
    vvCodFilial := NVL(pi_vCodFilialNf,pi_vCodFilial);
  
   /******
    UF ZFM
    ******/
    
    IF (UPPER(pi_vUf) = 'ZF') THEN
      
      BEGIN
        SELECT NVL(PCREGIAO.ALIQZFABCFARMA,'ZF')
          INTO vvUf
          FROM PCREGIAO
         WHERE (PCREGIAO.NUMREGIAO = pi_nNumRegiao);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
            
    END IF;
       
   /******************
    Exceção do Cliente
    ******************/
    
    vAchouExcecao := FALSE;
        
    -- DDVENDAS-38075 - PMC não entra nas Exceções
    IF (UPPER(pi_vTipoPreco) NOT IN ('PMC','PMCLICIT')) THEN
        
      -- Regra da Prioridade: Exceções do Convênio Isenção ICMS (existir um relacionamento na PCUFMEDABCFARMA para o código da exceção e o convênio '1' = Convênio Isenção ICMS)
      FOR vc_Excecao IN (SELECT E.CODEXCECAO
                              , NVL((SELECT 1 FROM PCUFMEDABCFARMA TB WHERE TB.UF = E.CODEXCECAO AND TB.TIPOMEDICAMENTO = '1' AND pi_vConvenioIsencao = 'S'),2) PRIORIDADE
                           FROM PCEXCECAOUFMEDABCFARMA E
                          WHERE ( (NOT EXISTS (SELECT 'S' FROM PCRESTRICAOUFMEDABCFARMA RF WHERE RF.CODEXCECAO = E.CODEXCECAO AND RF.TIPO = 'F')) OR
                                  (EXISTS (SELECT 'S' FROM PCRESTRICAOUFMEDABCFARMA RF WHERE RF.CODEXCECAO = E.CODEXCECAO AND RF.TIPO = 'F' AND RF.VALOR = vvCodFilial)) )
                            AND ( (NOT EXISTS (SELECT 'S' FROM PCRESTRICAOUFMEDABCFARMA RF WHERE RF.CODEXCECAO = E.CODEXCECAO AND RF.TIPO = 'U')) OR
                                  (EXISTS (SELECT 'S' FROM PCRESTRICAOUFMEDABCFARMA RF WHERE RF.CODEXCECAO = E.CODEXCECAO AND RF.TIPO = 'U' AND RF.VALOR = vvUf)) )     
                            AND (EXISTS (SELECT 'S' FROM PCRESTRICAOUFMEDABCFARMA RF WHERE RF.CODEXCECAO = E.CODEXCECAO AND RF.TIPO = 'C' AND RF.VALOR = pi_vTipoCliMed))
                          ORDER BY PRIORIDADE) LOOP
                            
        BEGIN
        
          SELECT CASE 
                   WHEN (UPPER(pi_vTipoPreco) = 'PF') THEN 
                     PRECOFABRICA
                   WHEN (UPPER(pi_vTipoPreco) = 'PFLICIT') THEN 
                     PRECOFABRICALICITTAB
                   ELSE
                     NULL
                 END                 
            INTO vnRetPreco
            FROM PCTABMEDABCFARMA
           WHERE (CODPROD = pi_nCodProd)
             AND (UF      = vc_Excecao.CODEXCECAO);
             
          --** ACHOU EXCEÇÃO **--
          vAchouExcecao := TRUE;
          
          -- Convênio CONFAZ 87 tem Prioridade, portanto não procura o próximo
          IF (NVL(pi_vConvenioIsencao,'N') = 'S') AND
             (NVL(vnRetPreco,0) > 0) THEN
            EXIT;
          END IF;                            
          
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- Se não encontrar mantém o último
            NULL;
        END;
                            
      END LOOP;
      
    END IF;
    
   /********************
    Se não achou Exceção
    ********************/
    
    IF (NOT vAchouExcecao) THEN

      BEGIN
        SELECT CASE 
                 WHEN (UPPER(pi_vTipoPreco) = 'PF') THEN 
                   PRECOFABRICA
                 WHEN (UPPER(pi_vTipoPreco) = 'PMC') THEN 
                   PRECOMAXCONSUM
                 WHEN (UPPER(pi_vTipoPreco) = 'PFLICIT') THEN 
                   PRECOFABRICALICITTAB
                 WHEN (UPPER(pi_vTipoPreco) = 'PMCLICIT') THEN 
                   PRECOMAXCONSUMLICITTAB
                 ELSE
                   NULL
               END                 
          INTO vnRetPreco
          FROM PCTABMEDABCFARMA
         WHERE (CODPROD = pi_nCodProd)
           AND (UF      = vvUf);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnRetPreco := 0;
      END;
      
      -- Se tabela Zona Franca e não achou a Alíquota, busca na ZF
      IF (UPPER(pi_vUf) = 'ZF')  AND 
         (NVL(vnRetPreco,0) = 0) THEN
         
        BEGIN
          SELECT CASE 
                   WHEN (UPPER(pi_vTipoPreco) = 'PF') THEN 
                     PRECOFABRICA
                   WHEN (UPPER(pi_vTipoPreco) = 'PMC') THEN 
                     PRECOMAXCONSUM
                   WHEN (UPPER(pi_vTipoPreco) = 'PFLICIT') THEN 
                     PRECOFABRICALICITTAB
                   WHEN (UPPER(pi_vTipoPreco) = 'PMCLICIT') THEN 
                     PRECOMAXCONSUMLICITTAB
                   ELSE
                     NULL
                 END                 
            INTO vnRetPreco
            FROM PCTABMEDABCFARMA
           WHERE (CODPROD = pi_nCodProd)
             AND (UF      = 'ZF');
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vnRetPreco := 0;
        END;
         
      END IF;
      
    END IF; -- Não Achou Exceção
    
   /*******
    Retorno
    *******/
    
    RETURN NVL(vnRetPreco,0);
            
  END F_OBTEM_PRECO_ABCFARMA;

  ---------------------------------------------------------------------------------------------------
  -- Função para Calcular o Descontos dos Benefícios Fiscais conforme Regra do Pacote - DDMEDICA-7584
  ---------------------------------------------------------------------------------------------------
  PROCEDURE P_CALC_DESC_PIS_COFINS_ICMS(pi_vCODFILIAL              IN VARCHAR2,
                                        pi_vCODFILIANF             IN VARCHAR2,
                                        pi_vCODFILIALRETIRA        IN VARCHAR2,
                                        pi_nCODCLI                 IN NUMBER,
                                        pi_nCODPROD                IN NUMBER,
                                        pi_nPRECOSEMIMPOSTOS       IN NUMBER,
                                        po_nVALOR_DESCONTO_PIS    OUT NUMBER,
                                        po_nPERC_DESCONTO_PIS     OUT NUMBER,
                                        po_nVALOR_DESCONTO_COFINS OUT NUMBER,
                                        po_PERC_DESCONTO_COFINS   OUT NUMBER,
                                        po_VALOR_DESCONTO_ICMS    OUT NUMBER,
                                        po_PERC_DESCONTO_ICMS     OUT NUMBER,
                                        po_VALOR_DESCONTO_SUFRAMA OUT NUMBER,
                                        po_PERC_DESCONTO_SUFRAMA  OUT NUMBER,
                                        po_vErros                 OUT VARCHAR2,
                                        po_vMsgErros              OUT VARCHAR2) IS
    
    -- Declaração de Variáveis da Função
    vvSql VARCHAR2(2000);

  BEGIN

    -- Inicializa Variáveis
    po_nVALOR_DESCONTO_PIS    := 0;
    po_nPERC_DESCONTO_PIS     := 0;
    po_nVALOR_DESCONTO_COFINS := 0;
    po_PERC_DESCONTO_COFINS   := 0;
    po_VALOR_DESCONTO_ICMS    := 0;
    po_PERC_DESCONTO_ICMS     := 0;
    po_VALOR_DESCONTO_SUFRAMA := 0;
    po_PERC_DESCONTO_SUFRAMA  := 0;
    po_vErros                 := 'N';
    po_vMsgErros              := NULL;

    -- BASE E VALOR DO ST
    BEGIN
      SELECT VALOR_DESCONTO_PIS
           , PERC_DESCONTO_PIS
           , VALOR_DESCONTO_COFINS
           , PERC_DESCONTO_COFINS
           , VALOR_DESCONTO_ICMS
           , PERC_DESCONTO_ICMS
           , VALOR_DESCONTO_SUFRAMA
           , PERC_DESCONTO_SUFRAMA
        INTO po_nVALOR_DESCONTO_PIS
           , po_nPERC_DESCONTO_PIS
           , po_nVALOR_DESCONTO_COFINS
           , po_PERC_DESCONTO_COFINS
           , po_VALOR_DESCONTO_ICMS
           , po_PERC_DESCONTO_ICMS
           , po_VALOR_DESCONTO_SUFRAMA
           , po_PERC_DESCONTO_SUFRAMA
        FROM TABLE(PKG_TRIBUTACAO.CALCULAR_DESC_PIS_COFINS_ICMS(pi_vCODFILIAL, 
                                                                pi_vCODFILIANF,
                                                                NULL,
                                                                NVL(pi_nCODCLI,0),
                                                                NVL(pi_nCODPROD,0),
                                                                NVL(pi_nPRECOSEMIMPOSTOS,0),
                                                                0,     -- pNumEmpenho
                                                                0,     -- pPrazoMedioPedido
                                                                'N')); -- pVendaTriangular      
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        po_nVALOR_DESCONTO_PIS    := 0;
        po_nPERC_DESCONTO_PIS     := 0;
        po_nVALOR_DESCONTO_COFINS := 0;
        po_PERC_DESCONTO_COFINS   := 0;
        po_VALOR_DESCONTO_ICMS    := 0;
        po_PERC_DESCONTO_ICMS     := 0;
        po_VALOR_DESCONTO_SUFRAMA := 0;
        po_PERC_DESCONTO_SUFRAMA  := 0;
    END;
    
  EXCEPTION
    WHEN OTHERS THEN
      po_vErros    := 'S';
      po_vMsgErros := 'Erro no cálculo dos benefícios fiscais (PKG_TRIBUTACAO): ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ' >>' || SQLERRM; 
  END P_CALC_DESC_PIS_COFINS_ICMS;  
  
  /*******************************************************************************
   Nome         : F_GET_SOMADESCUNITBENEFFISCAIS - DDMEDICA-7584
   Descricão    : Função para retornar o somatório dos valores unitários dos descontos de benefícios fiscais
   Parâmetros   : ENTRADA:
                  pi_nVLDESCICMISENCAO
                  pi_nVLDESCSUFRAMA
                  pi_nVLDESCPISSUFRAMA
                  pi_nVLDESCREDUCAOPIS
                  pi_nVLDESCREDUCAOCOFINS
  **********************************************************************************/                                       
  FUNCTION F_GET_SOMADESCUNITBENEFFISCAIS(pi_nVLDESCICMISENCAO    IN NUMBER,
                                          pi_nVLDESCSUFRAMA       IN NUMBER,
                                          pi_nVLDESCPISSUFRAMA    IN NUMBER,
                                          pi_nVLDESCREDUCAOPIS    IN NUMBER,
                                          pi_nVLDESCREDUCAOCOFINS IN NUMBER) 
  RETURN NUMBER IS
    vnRetSomaDescUnitBenefFiscais NUMBER;
  BEGIN
   
    -- Inicializa Retorno
    vnRetSomaDescUnitBenefFiscais := 0;
  
    -- Somatório dos Descontos dos Benefícios Fiscais
    IF (NVL(pi_nVLDESCICMISENCAO,0) > 0) THEN 
      vnRetSomaDescUnitBenefFiscais := NVL(vnRetSomaDescUnitBenefFiscais,0) + NVL(pi_nVLDESCICMISENCAO,0);
    END IF;      
    IF ((NVL(pi_nVLDESCSUFRAMA,0) + NVL(pi_nVLDESCPISSUFRAMA,0)) > 0) then
      vnRetSomaDescUnitBenefFiscais := NVL(vnRetSomaDescUnitBenefFiscais,0) + (NVL(pi_nVLDESCSUFRAMA,0) + NVL(pi_nVLDESCPISSUFRAMA,0));
    END IF;
    IF ((NVL(pi_nVLDESCREDUCAOPIS,0) + NVL(pi_nVLDESCREDUCAOCOFINS,0)) > 0) then
      vnRetSomaDescUnitBenefFiscais := NVL(vnRetSomaDescUnitBenefFiscais,0) + (NVL(pi_nVLDESCREDUCAOPIS,0) + NVL(pi_nVLDESCREDUCAOCOFINS,0));
    END IF;  
  
    -- Retorno
    RETURN vnRetSomaDescUnitBenefFiscais;
    
  END F_GET_SOMADESCUNITBENEFFISCAIS;
                       
  ------------------------------------------------------------------------------
  -- Procedimento para arredondar o calculo do Suframa - DDMEDICA-7594
  ------------------------------------------------------------------------------
  FUNCTION F_ARREDONDAMENTO_SUFRAMA(pi_nValor            IN NUMBER,
                                    pi_vNumCasasDecimais IN NUMBER,
                                    pi_vTipoCalcSuframa  IN VARCHAR2)
  RETURN NUMBER IS
    vValorSuframa NUMBER;
  BEGIN

    IF NVL(pi_vTipoCalcSuframa,' ') = 'T2' THEN
      SELECT TRUNC(pi_nValor,2) INTO vValorSuframa FROM DUAL;
    ELSE
      IF NVL(pi_vTipoCalcSuframa,' ') = 'A2' THEN
        SELECT ROUND(pi_nValor,2) INTO vValorSuframa FROM DUAL;
      ELSE
        SELECT ROUND(pi_nValor,pi_vNumCasasDecimais) INTO vValorSuframa FROM DUAL;
      END IF;
    END IF;

    -- Retorno
    RETURN NVL(vValorSuframa,0);

  END F_ARREDONDAMENTO_SUFRAMA;

  ------------------------------------------------------------------------------
  -- Procedimento para arredondar o calculo da desoneração - DDMEDICA-7594
  ------------------------------------------------------------------------------
  FUNCTION F_ARREDONDAMENTO_DESONERACAO(pi_nValor            IN NUMBER,
                                        pi_vNumCasasDecimais IN NUMBER,
                                        pi_vRegraMinimo      IN VARCHAR2,
                                        pi_nCodSt            IN NUMBER)
  RETURN NUMBER IS
    nValorDesoneracao NUMBER;
    vDESTACDESCICMISENCAOCOMERCIAL PCTRIBUT.DESTACDESCICMISENCAOCOMERCIAL%TYPE;
  BEGIN

    SELECT ROUND(pi_nValor,pi_vNumCasasDecimais) INTO nValorDesoneracao FROM DUAL;
    
    IF (nValorDesoneracao = 0) AND
       (pi_vRegraMinimo = 'S') THEN
      BEGIN
        SELECT PCTRIBUT.DESTACDESCICMISENCAOCOMERCIAL
          INTO vDESTACDESCICMISENCAOCOMERCIAL
          FROM PCTRIBUT
         WHERE (PCTRIBUT.CODST = pi_nCodSt);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vDESTACDESCICMISENCAOCOMERCIAL := 'N';
      END;
      IF (NVL(vDESTACDESCICMISENCAOCOMERCIAL,'N') <> 'S') THEN -- Isenção ST não participa da Regra
        -- Condicionar às casas decimais do preço de venda para não gerar preço negativo
        IF    (NVL(pi_vNumCasasDecimais,2) = 3) THEN
          nValorDesoneracao := 0.001;
        ELSIF (NVL(pi_vNumCasasDecimais,2) = 4) THEN
          nValorDesoneracao := 0.0001;
        ELSIF (NVL(pi_vNumCasasDecimais,2) = 5) THEN
          nValorDesoneracao := 0.00001;
        ELSIF (NVL(pi_vNumCasasDecimais,2) = 6) THEN
          nValorDesoneracao := 0.000001;
        ELSE
          nValorDesoneracao := 0.01;
        END IF;
      END IF;
    END IF;

    -- Retorno
    RETURN NVL(nValorDesoneracao,0);

  END F_ARREDONDAMENTO_DESONERACAO;
          
 /*******************************************************************************
  Nome     : P_BUSCARDADOSENDERECOENTREGA - DDVENDAS-33718
  Descricão: Procedimento para retornar os dados do endereço de entrega do cliente
  ********************************************************************************/                                         
  PROCEDURE P_BUSCARDADOSENDERECOENTREGA(pCodCli    IN NUMBER,
                                         pCodEndEnt IN NUMBER,
                                         pEsEnt     IN VARCHAR2,
                                         pNumRegiao IN OUT NUMBER,
                                         pUfEnt     IN OUT VARCHAR2,
                                         pPracaEnt  IN OUT NUMBER) IS
  BEGIN
  
    pNumRegiao := 0;
    pUfEnt     := NULL;
    pPracaEnt  := 0;
  
    IF (NVL(pCodEndEnt,0) > 0) THEN
    
      BEGIN
        SELECT ESTENT
             , NUMREGIAO
             , NVL(CODPRACAENT, 0) CODPRACAENT
          INTO pUfEnt
             , pNumRegiao
             , pPracaEnt             
          FROM PCCLIENTENDENT
         WHERE CODENDENTCLI = pCodEndEnt
           AND CODCLI = pCodCli;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;      
      
    END IF;
  
  END P_BUSCARDADOSENDERECOENTREGA;

 /*******************************************************************************
  Nome     : P_RETORNARUFENTENDENT - DDVENDAS-33718
  Descricão: Procedimento para retornar a UF do Endereço de Entrega do Cliente
  ********************************************************************************/                                         
  PROCEDURE P_RETORNARUFENTENDENT(pCodCli      IN NUMBER,
                                  pCodEndEnt   IN NUMBER,
                                  pEstEnt      IN VARCHAR2,
                                  pNumRegiao   IN OUT NUMBER,
                                  psUF         IN OUT VARCHAR2,
                                  pCodPracaEnt IN OUT NUMBER) IS
    vnRegiao   PCREGIAO.NUMREGIAO%TYPE;
    vsUf       PCCLIENT.ESTENT%TYPE;
    vnPracaEnt PCPRACA.CODPRACA%TYPE;
  BEGIN
  
    vsUf       := pEstEnt;
    vnPracaEnt := 0;
  
    IF (NVL(pCodEndEnt,0) > 0) THEN
    
      P_BUSCARDADOSENDERECOENTREGA(pCodCli
                                  ,pCodEndEnt
                                  ,pEstEnt
                                  ,vnRegiao
                                  ,vsUf
                                  ,vnPracaEnt);    
    
      IF (NVL(vnRegiao,0) > 0) THEN
        pNumRegiao := vnRegiao;
      END IF;
    
      IF (NVL(vnPracaEnt,0) <> 0) then
        pCodPracaEnt := vnPracaEnt;
      END IF;
    
      IF (vsUf IS NOT NULL) THEN
        psUF := vsUf;
      END IF;
        
    END IF;
    
  END P_RETORNARUFENTENDENT;

 /*******************************************************************************
  Nome     : F_DEFINIRNUMREGIAOPEDIDO - DDVENDAS-33718
  Descricão: Função para definir a Região do Pedido baseado no Endereço de Entrega do Cliente
  ********************************************************************************/                                         
  FUNCTION F_DEFINIRNUMREGIAOPEDIDO(pCodCli            IN NUMBER,
                                    pNumRegiao         IN NUMBER,
                                    pUtilizaTribEndEnt IN VARCHAR2,
                                    pCodEndEnt         IN NUMBER,
                                    pEstEnt            IN VARCHAR2)
  RETURN NUMBER IS
    vnRetNumRegiao    PCREGIAO.NUMREGIAO%TYPE;
    vnNumRegiaoEndEnt PCREGIAO.NUMREGIAO%TYPE;
    vsUfEnt           PCCLIENT.ESTENT%TYPE;
    vnCodPracaEnt     PCPRACA.CODPRACA%TYPE;
  BEGIN
  
    -- Inicializa a Região com o valor recebido no Parâmetro
    vnRetNumRegiao := pNumRegiao;
  
    -- Se utilizar Tributação pelo Endereço de Entrega e informou o Endereço de Entrega
    IF (NVL(pUtilizaTribEndEnt,'N') = 'S') AND
       (NVL(pCodEndEnt,0) > 0)             THEN

      P_RETORNARUFENTENDENT(pCodCli,
                            pCodEndEnt,
                            pEstEnt,
                            vnNumRegiaoEndEnt,
                            vsUfEnt,
                            vnCodPracaEnt);
      IF (NVL(vnNumRegiaoEndEnt,0) > 0) THEN
        vnRetNumRegiao := vnNumRegiaoEndEnt;
      END IF;
      
    END IF;
  
    -- Retorna a Região
    RETURN vnRetNumRegiao;
    
  END F_DEFINIRNUMREGIAOPEDIDO;
  
 /*******************************************************************************
  Nome     : F_DEFINIRNUMREGIAOPEDIDO - DDVENDAS-33718
  Descricão: Função para definir a UF de Destino do Pedido baseado no Endereço de Entrega do Cliente
  ********************************************************************************/                                         
  FUNCTION F_DEFINIRUFDESTINOPEDIDO(pCodCli            IN NUMBER,
                                    pUtilizaTribEndEnt IN VARCHAR2,
                                    pCodEndEnt         IN NUMBER,
                                    pEstEnt            IN VARCHAR2)
  RETURN VARCHAR2 IS
    vsRetEstDestino   PCCLIENT.ESTENT%TYPE;
    vnNumRegiaoEndEnt PCREGIAO.NUMREGIAO%TYPE;
    vsUfEndEnt        PCCLIENT.ESTENT%TYPE;
    vnCodPracaEnt     PCPRACA.CODPRACA%TYPE;
  BEGIN
  
    -- Inicia com ESTENT do Cliente
    vsRetEstDestino := pEstEnt;
  
    -- Se utilizar Tributação pelo Endereço de Entrega e informou o Endereço de Entrega
    IF (NVL(pUtilizaTribEndEnt,'N') = 'S') AND
       (NVL(pCodEndEnt,0) > 0) THEN
       
      P_RETORNARUFENTENDENT(pCodCli,
                            pCodEndEnt,
                            pEstEnt,
                            vnNumRegiaoEndEnt,
                            vsUfEndEnt,
                            vnCodPracaEnt);
      IF (NVL(vnNumRegiaoEndEnt,0) > 0) AND
         (vsUfEndEnt IS NOT NULL) THEN
        vsRetEstDestino := vsUfEndEnt;
      END IF;
      
    END IF;
  
    RETURN vsRetEstDestino;
    
  END F_DEFINIRUFDESTINOPEDIDO;          

  /*******************************************************************************
   Nome         : P_TAXACORDOPARCERIA
   Descrição    : Procedimento para retornar a Taxa de Desconto a Aplicar sobre o Preço Tabela
   Parâmetros   : ENTRADA:
                  pi_vCodFilial        = Código da Filial
                  pi_vCodFilialNf      = Código da Filial NF
                  pi_nCodProd          = Código do Produto
                  pi_nCodCli           = Código do Cliente
                  pi_nNumRegiao        = Número da Região
                  pi_nCondVenda        = Tipo de Venda
                  pi_vOrigemPed        = Origem do Pedido
                  pi_vTipoFv           = Tipo de FV
                  pi_nIntegradora      = Integradora
                  pi_dDtBase           = Data Base 
                  pi_vTipoChamada      = 'T' - Taxa de Desconto a Aplicar sobre o 
                                               Preço Tabela
                                         'F' - Desconto Financeiro      
                  SAIDA:
                  po_nCodAcordo        = Código do Acordo de Parceria
                  po_nPercTaxa         = % Taxa
                  po_nPerCom           = % Comissão
                  po_vCampo            = Campo referenciado
   Alteração    : Anderson Silva - 25/06/2014 - Criação da Função
   Alteração    : Anderson Silva - 10/12/2017 - Chamada Desc. Financeiro
  ********************************************************************************/
  PROCEDURE P_TAXACORDOPARCERIA(pi_vCodFilial       IN  VARCHAR2,
                                pi_vCodFilialNf     IN  VARCHAR2,
                                pi_nCodProd         IN  NUMBER,
                                pi_nCodCli          IN  NUMBER,
                                pi_nNumRegiao       IN  NUMBER,
                                pi_nCondVenda       IN  NUMBER,
                                pi_vOrigemPed       IN  VARCHAR2,
                                pi_vTipoFv          IN  VARCHAR2,
                                pi_nIntegradora     IN  NUMBER,
                                pi_nCodPlPag        IN  NUMBER,
                                pi_dDtBase          IN  DATE,
                                po_vAchouTaxa       OUT VARCHAR2,
                                po_nCodAcordo       OUT NUMBER,
                                po_nPercTaxa        OUT NUMBER,
                                po_nPerCom          OUT NUMBER,
                                po_vCampo           OUT VARCHAR2,
                                pi_vTipoChamada     IN  VARCHAR2 DEFAULT 'T')
  IS
  
    -- Dados do Cliente
    vnCodRede              PCCLIENT.CODREDE%TYPE;
    vnCodAtv1              PCCLIENT.CODATV1%TYPE;
     
    -- Origem do Pedido
    vvCodOrigemPed          PCACORDOPARCERIAORIG.CODORIG%TYPE;
    
    -- RegiÃ£o
    v_numregiao             PCREGIAO.NUMREGIAO%TYPE;
    -- PraÃ§a
    v_codpraca              PCCLIENT.CODPRACA%TYPE;
    
    -- Tipo de Acordo 
    v_tipoacordo            PCACORDOPARCERIA.TIPOACORDO%TYPE;
    
    --------------------------------------------------------------------------------------
    -- Procedimento: P_OBTER_TAXA
    -- DescriÃ§Ã£o...: Obtem a Taxa para o Acordo
    --------------------------------------------------------------------------------------
    PROCEDURE P_OBTER_TAXA(pi_nCodAcordo  IN NUMBER,
                           pi_nCodProd    IN NUMBER,
                           pio_vAchouTaxa IN OUT VARCHAR2,
                           pio_nCodAcordo IN OUT NUMBER,
                           pio_nPercTaxa  IN OUT NUMBER,
                           pio_nPerCom    IN OUT NUMBER,
                           pio_vCampo     IN OUT VARCHAR2)
    IS
      -- Dados do Acordo
      v_status       PCACORDOPARCERIA.STATUS%TYPE;
      -- Dados do Produto
      vnCodFornec    PCPRODUT.CODFORNEC%TYPE;
      vnCodLinhaProd PCPRODUT.CODLINHAPROD%TYPE;
      vnCodepto      PCPRODUT.CODEPTO%TYPE;
      vnCodSec       PCPRODUT.CODSEC%TYPE;
      vnCodMarca     PCPRODUT.CODMARCA%TYPE;
    BEGIN
    
      -- Pesquisa Dados do Acordo encontrado
      BEGIN
        SELECT CASE WHEN (NVL(TIPOACORDO,'A') IN ('D','F')) THEN
                 -- Acordo Exclusivo de Desconto e AcrÃ©scimo OU Desconto Financeiro sempre Ã© Liberado
                 'L'
               ELSE
                 STATUS
               END STATUS
          INTO v_status
          FROM PCACORDOPARCERIA
         WHERE (CODACORDO = pi_nCodAcordo); -->> CÃ³digo do Acordo encontrado   
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_status := NULL;
      END;      
    
      -- Se Acordo VÃ¡lido: Se encontrou o Acordo e estÃ¡ Liberado
      IF (v_status = 'L') THEN
          
        -- Pesquisa informaÃ§Ãµes do produto
        BEGIN
          SELECT PCPRODUT.CODMARCA             
               , PCPRODUT.CODLINHAPROD
            INTO vnCodMarca         
               , vnCodLinhaProd
            FROM PCPRODUT
           WHERE (PCPRODUT.CODPROD = pi_nCodProd);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vnCodMarca     := NULL;    
            vnCodLinhaProd := NULL;
        END;
        
        -- Pesquisa Taxa
        FOR vc_Taxa IN (SELECT CODACORDO
                             , CAMPO
                             , CODIGO
                             , PERCENTUAL
                             , PERCOM
                             , CASE 
                                 WHEN (CAMPO = 'PR') THEN
                                   1
                                 WHEN (CAMPO = 'GP') THEN
                                   2
                                 WHEN (CAMPO = 'MA') THEN
                                   3
                                 WHEN (CAMPO = 'LP') THEN
                                   4
                               END PRIORIDADE
                          FROM PCACORDOPARCERIADESCACRESC
                         WHERE (CODACORDO = pi_nCodAcordo) -->> Pesquisa Taxa no Acordo encontrado
                           AND ( ((CAMPO = 'PR') AND (CODIGO = pi_nCodProd)) OR
                                 ((CAMPO = 'MA') AND (CODIGO = vnCodMarca)) OR 
                                 ((CAMPO = 'GP') AND (CODIGO = (SELECT PCGRUPOSCAMPANHAI.CODGRUPO
                                                                  FROM PCGRUPOSCAMPANHAI
                                                                 WHERE PCGRUPOSCAMPANHAI.DTEXCLUSAO IS NULL
                                                                   AND PCGRUPOSCAMPANHAI.CODGRUPO = PCACORDOPARCERIADESCACRESC.CODIGO
                                                                   AND PCGRUPOSCAMPANHAI.CODITEM  = pi_nCodProd))) OR
                                 ((CAMPO = 'LP') AND (CODIGO = vnCodLinhaProd)) )
                         ORDER BY PRIORIDADE) LOOP
     
          -- Pega os Dados da Taxa
          pio_vAchouTaxa := 'S';
          pio_nCodAcordo := vc_Taxa.CODACORDO;
          pio_nPercTaxa  := vc_Taxa.PERCENTUAL;
          pio_nPerCom    := vc_Taxa.PERCOM;
          pio_vCampo     := vc_Taxa.CAMPO || '-' || vc_Taxa.CODIGO;
          -- Sai
          EXIT;
          
        END LOOP; -- Fim LaÃ§o Pesquisa Taxa
         
      END IF; -- Fim CondiÃ§Ã£o: Se Acordo VÃ¡lido: Se encontrou o Acordo e estÃ¡ Liberado      
      
    END P_OBTER_TAXA;
      
    --------------------------------------------------------------------------------------
    -- FunÃ§Ã£o...: F_ACORDO_RESTRICAO_VALIDO
    -- DescriÃ§Ã£o: Verifica se a RegiÃ£o Ã© VÃ¡lida para as RestriÃ§Ãµes passadas nos ParÃ¢metros
    --------------------------------------------------------------------------------------
    FUNCTION F_ACORDO_RESTRICAO_VALIDO(pi_nParamCodAcordo IN NUMBER,
                                       pi_nParamNumRegiao IN NUMBER,
                                       pi_nParamCodPlPag  IN NUMBER)
    RETURN VARCHAR2 IS
  
      vvAcordoValido VARCHAR2(1);
      vvRegiaoValida VARCHAR2(1);
      vvPlanoValido  VARCHAR2(1);
      vvAchouRegiao  VARCHAR2(1);
      vvAchouPlano   VARCHAR2(1);
      
    BEGIN
      
      -- Inicializa Retorno
      vvAcordoValido := 'N';
      
      -- RESTRIÃ‡Ã•ES DE REGIÃƒO ---------------------
      
      vvRegiaoValida := 'N';
      
      -- Verifica se tem alguma RestriÃ§Ã£o de RegiÃ£o
      BEGIN
        SELECT 'S' 
          INTO vvAchouRegiao
          FROM PCACORDOPARCERIAREGIAO
         WHERE (CODACORDO = pi_nParamCodAcordo)
           AND (ROWNUM    = 1);
      EXCEPTION 
        WHEN NO_DATA_FOUND THEN
          vvAchouRegiao := 'N';
      END; 
      
      -- Se existem RestriÃ§Ãµes de RegiÃ£o
      IF (NVL(vvAchouRegiao,'N') = 'S') THEN
      
        -- Verifica se a RegiÃ£o estÃ¡ nas RestriÃ§Ãµes
        BEGIN
          SELECT 'S' 
            INTO vvAchouRegiao
            FROM PCACORDOPARCERIAREGIAO
           WHERE (CODACORDO = pi_nParamCodAcordo)
             AND (NUMREGIAO = pi_nParamNumRegiao);
        EXCEPTION 
          WHEN NO_DATA_FOUND THEN
            vvAchouRegiao := 'N';
        END; 
        
        -- Se a RegiÃ£o estÃ¡ nas RestriÃ§Ãµes
        IF (vvAchouRegiao = 'S') THEN
          -- REGIÃƒO VÃLIDA
          vvRegiaoValida := 'S';
        END IF;
      
      -- Se NÃƒO existem RestriÃ§Ãµes de RegiÃ£o
      ELSE
  
        -- REGIÃƒO VÃLIDA
        vvRegiaoValida := 'S';
  
      END IF; -- Fim CondiÃ§Ã£o: -- Se existem RestriÃ§Ãµes de RegiÃ£o
      
      -- SE REGIÃƒO VÃLIDA
      IF (vvRegiaoValida = 'S') THEN
      
        -- RESTRIÃ‡Ã•ES DE PLANO DE PARAMENTO ---------------------
        
        vvPlanoValido := 'N';
        
        -- Verifica se tem alguma RestriÃ§Ã£o de Plano de Pagamentp
        BEGIN
          SELECT 'S' 
            INTO vvAchouPlano
            FROM PCACORDOPARCERIAPLPAG
           WHERE (CODACORDO = pi_nParamCodAcordo)
             AND (ROWNUM    = 1);
        EXCEPTION 
          WHEN NO_DATA_FOUND THEN
            vvAchouPlano := 'N';
        END; 
        
        -- Se existem RestriÃ§Ãµes de Plano de Pagamento
        IF (NVL(vvAchouPlano,'N') = 'S') THEN
        
          -- Verifica se o Plano de Pagamento estÃ¡ nas RestriÃ§Ãµes
          BEGIN
            SELECT 'S' 
              INTO vvAchouPlano
              FROM PCACORDOPARCERIAPLPAG
             WHERE (CODACORDO = pi_nParamCodAcordo)
               AND (CODPLPAG  = pi_nParamCodPlPag);
          EXCEPTION 
            WHEN NO_DATA_FOUND THEN
              vvAchouPlano := 'N';
          END; 
          
          -- Se o Plano de Pagamento estÃ¡ nas RestriÃ§Ãµes
          IF (vvAchouPlano = 'S') THEN
            -- PLANO DE PAGAMENTO VÃLIDO
            vvPlanoValido := 'S';
          END IF;
        
        -- Se NÃƒO existem RestriÃ§Ãµes de Plano de Pagamento
        ELSE
    
          -- PLANO DE PAGAMENTO VÃLIDO
          vvPlanoValido := 'S';
    
        END IF; -- Fim CondiÃ§Ã£o: -- Se existem RestriÃ§Ãµes de Plano de Pagamento
        
        -- SE PLANO DE PAGAMENTO VÃLIDO
        IF (vvPlanoValido = 'S') THEN
       
          -- *** ACORDO DE PARCERIA VÃLIDO *** --
          vvAcordoValido := 'S';
  
        END IF;
          
      END IF; -- FIM CONDIÃ‡ÃƒO: SE REGIÃƒO VÃLIDA
      
      -- Retorno
      RETURN vvAcordoValido;
      
    END F_ACORDO_RESTRICAO_VALIDO;
    
   /*********************************
    INICIO DO PROCESSAMENTO PRINCIPAL
    *********************************/    
  BEGIN
  
    -- Inicializa Retornos
    po_vAchouTaxa := 'N';
    po_nCodAcordo := NULL;
    po_nPercTaxa  := NULL;
    po_nPerCom    := NULL;
    po_vCampo     := NULL;
    
    -- Tipo de Acordo 
    v_tipoacordo  := 'D';
    IF (pi_vTipoChamada = 'F') THEN
      v_tipoacordo := 'F';
    END IF;  
      
    -- Define a Origem do Pedido
    IF    (pi_vOrigemPed = 'F') AND (NVL(pi_vTipoFv,'FV') = 'OL') THEN
      vvCodOrigemPed := 'L';
    ELSIF (pi_vOrigemPed = 'F') AND (NVL(pi_vTipoFv,'FV') = 'PE') THEN
      vvCodOrigemPed := 'E';
    ELSE
      vvCodOrigemPed := pi_vOrigemPed;
    END IF;
  
    -- Se passou a RegiÃ£o no ParÃ¢metro
    IF (NVL(pi_nNumRegiao,0) > 0) THEN
        
      v_numregiao := pi_nNumRegiao;
          
    -- Se NÃƒO passou a RegiÃ£o no ParÃ¢metro
    ELSE
      
      -- Pesquisa Dados do Cliente
      BEGIN
        SELECT CODPRACA      
          INTO v_codpraca
          FROM PCCLIENT
         WHERE (CODCLI = pi_nCodCli);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
      
      -- Pesquisa RegiÃ£o do Cliente por Filial
      BEGIN
        SELECT NUMREGIAO
          INTO v_numregiao
          FROM PCTABPRCLI
         WHERE (CODCLI      = pi_nCodCli)
           AND (CODFILIALNF = pi_vCodFilial);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_numregiao := NULL;
      END;
        
      -- Se nÃ£o achou Regiao do Cliente por Filial
      IF (v_numregiao IS NULL) THEN
         -- Pesquisa RegiÃ£o da PraÃ§a
         BEGIN
           SELECT NUMREGIAO
             INTO v_numregiao
             FROM PCPRACA
            WHERE (CODPRACA = v_codpraca);
         EXCEPTION
          WHEN NO_DATA_FOUND THEN
             v_numregiao := NULL;
         END;
       END IF;
       
    END IF; -- Fim CondiÃ§Ã£o: Se passou a RegiÃ£o no ParÃ¢metro
    
    ---------------------------------
    -- Pesquisa Acordo para o Cliente
    ---------------------------------  
    FOR vc_Acordo IN (SELECT PCACORDOPARCERIA.CODACORDO                         
                        FROM PCACORDOPARCERIA
                           , PCACORDOPARCERIAORIG
                           , PCACORDOPARCERIACLI                         
                       WHERE (PCACORDOPARCERIA.CODACORDO   = PCACORDOPARCERIAORIG.CODACORDO)
                         AND (PCACORDOPARCERIA.CODACORDO   = PCACORDOPARCERIACLI.CODACORDO)
                         AND (PCACORDOPARCERIAORIG.CODORIG = vvCodOrigemPed)
                         AND (PCACORDOPARCERIACLI.CODCLI   = pi_nCodCli)
                         AND (PCACORDOPARCERIA.CODACORDO   IN (SELECT PCACORDOPARCERIADESCACRESC.CODACORDO FROM PCACORDOPARCERIADESCACRESC)) -->> Somente Acordos com Taxa
                         AND (PCACORDOPARCERIA.TIPOACORDO  = v_tipoacordo) -->> Tipo de Acordo conforme Tipo de Chamada
                         AND (pi_dDtBase BETWEEN TRUNC(PCACORDOPARCERIA.DTVIGENCIAINI) AND TRUNC(PCACORDOPARCERIA.DTVIGENCIAFIN))) LOOP
                         
      -- Se RegiÃ£o e Plano de Pagamento VÃ¡lidos
      IF (F_ACORDO_RESTRICAO_VALIDO(vc_Acordo.CODACORDO,
                                    pi_nNumRegiao,
                                    pi_nCodPlPag) = 'S') THEN
        -- Pesquisa Taxa para o Acordo encontrado                            
        P_OBTER_TAXA(vc_Acordo.CODACORDO,
                     pi_nCodProd,
                     po_vAchouTaxa,
                     po_nCodAcordo,
                     po_nPercTaxa,
                     po_nPerCom,
                     po_vCampo);
        -- Se Achou a Taxa
        IF (po_vAchouTaxa = 'S') THEN
          -- Sai
          EXIT;
        END IF;                                                               
      END IF;                                               
                         
    END LOOP;
    
    -- Se nÃ£o achou Taxa para o Cliente
    IF (po_vAchouTaxa = 'N') THEN
    
      -- Pesquisa Dados do Cliente
      ----------------------------
      BEGIN
        SELECT CODREDE
             , CODATV1
          INTO vnCodRede
             , vnCodAtv1
          FROM PCCLIENT
         WHERE (PCCLIENT.CODCLI = pi_nCodCli);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnCodRede := NULL;
          vnCodAtv1 := NULL;
      END;
    
      ------------------------------------------
      -- Pesquisa Acordo para a Rede de Clientes
      ------------------------------------------
      FOR vc_Acordo IN (SELECT PCACORDOPARCERIA.CODACORDO                         
                          FROM PCACORDOPARCERIA
                             , PCACORDOPARCERIAORIG
                             , PCACORDOPARCERIAREDECLI                         
                         WHERE (PCACORDOPARCERIA.CODACORDO      = PCACORDOPARCERIAORIG.CODACORDO)
                           AND (PCACORDOPARCERIA.CODACORDO      = PCACORDOPARCERIAREDECLI.CODACORDO)
                           AND (PCACORDOPARCERIAORIG.CODORIG    = vvCodOrigemPed)
                           AND (PCACORDOPARCERIAREDECLI.CODREDE = vnCodRede)
                           AND (PCACORDOPARCERIA.TIPOACORDO     = v_tipoacordo) -->> Tipo de Acordo conforme Tipo de Chamada
                           AND (PCACORDOPARCERIA.CODACORDO     IN (SELECT PCACORDOPARCERIADESCACRESC.CODACORDO FROM PCACORDOPARCERIADESCACRESC)) -->> Somente Acordos com Taxa
                           AND (pi_dDtBase BETWEEN TRUNC(PCACORDOPARCERIA.DTVIGENCIAINI) AND TRUNC(PCACORDOPARCERIA.DTVIGENCIAFIN))) LOOP
                           
        -- Se RegiÃ£o e Plano de Pagamento VÃ¡lidos
        IF (F_ACORDO_RESTRICAO_VALIDO(vc_Acordo.CODACORDO,
                                      pi_nNumRegiao,
                                      pi_nCodPlPag) = 'S') THEN         
          -- Pesquisa Taxa para o Acordo encontrado                            
          P_OBTER_TAXA(vc_Acordo.CODACORDO,
                       pi_nCodProd,
                       po_vAchouTaxa,
                       po_nCodAcordo,
                       po_nPercTaxa,
                       po_nPerCom,
                       po_vCampo);
          -- Se Achou a Taxa
          IF (po_vAchouTaxa = 'S') THEN
            -- Sai
            EXIT;
          END IF;                                                               
        END IF;                                               
                           
      END LOOP;
      
      -- Se nÃ£o achou Texa para a Rede de Clientes
      IF (po_vAchouTaxa = 'N') THEN
          
        -------------------------------------------
        -- Pesquisa Acordo para o Ramo de Atividade
        -------------------------------------------
        FOR vc_Acordo IN (SELECT PCACORDOPARCERIA.CODACORDO                         
                            FROM PCACORDOPARCERIA
                               , PCACORDOPARCERIAORIG
                               , PCACORDOPARCERIARAMOATIV
                           WHERE (PCACORDOPARCERIA.CODACORDO       = PCACORDOPARCERIAORIG.CODACORDO)
                             AND (PCACORDOPARCERIA.CODACORDO       = PCACORDOPARCERIARAMOATIV.CODACORDO)
                             AND (PCACORDOPARCERIAORIG.CODORIG     = vvCodOrigemPed)
                             AND (PCACORDOPARCERIARAMOATIV.CODATIV = vnCodAtv1)
                             AND (PCACORDOPARCERIA.TIPOACORDO      = v_tipoacordo) -->> Tipo de Acordo conforme Tipo de Chamada
                             AND (PCACORDOPARCERIA.CODACORDO       IN (SELECT PCACORDOPARCERIADESCACRESC.CODACORDO FROM PCACORDOPARCERIADESCACRESC)) -->> Somente Acordos com Taxa
                             AND (pi_dDtBase BETWEEN TRUNC(PCACORDOPARCERIA.DTVIGENCIAINI) AND TRUNC(PCACORDOPARCERIA.DTVIGENCIAFIN))) LOOP
                             
          -- Se RegiÃ£o e Plano de Pagamento VÃ¡lidos
          IF (F_ACORDO_RESTRICAO_VALIDO(vc_Acordo.CODACORDO,
                                        pi_nNumRegiao,
                                        pi_nCodPlPag) = 'S') THEN
            -- Pesquisa Taxa para o Acordo encontrado                            
            P_OBTER_TAXA(vc_Acordo.CODACORDO,
                         pi_nCodProd,
                         po_vAchouTaxa,
                         po_nCodAcordo,
                         po_nPercTaxa,
                         po_nPerCom,
                         po_vCampo);
            -- Se Achou a Taxa
            IF (po_vAchouTaxa = 'S') THEN
              -- Sai
              EXIT;
            END IF;                                                               
          END IF;                                               
                             
        END LOOP;
  
        -- Se nÃ£o achou Taxa para o Ramo de Atividade
        IF (po_vAchouTaxa = 'N') THEN
              
          -----------------------------------------------
          -- Pesquisa Acordo Geral para todos os Clientes
          ----------------------------------------------
          FOR vc_Acordo IN (SELECT PCACORDOPARCERIA.CODACORDO                         
                              FROM PCACORDOPARCERIA
                                 , PCACORDOPARCERIAORIG
                             WHERE (PCACORDOPARCERIA.CODACORDO   = PCACORDOPARCERIAORIG.CODACORDO)
                               AND (PCACORDOPARCERIAORIG.CODORIG = vvCodOrigemPed)
                               AND (PCACORDOPARCERIA.TIPOACORDO  = v_tipoacordo) -->> Tipo de Acordo conforme Tipo de Chamada
                               AND (PCACORDOPARCERIA.CODACORDO   IN (SELECT PCACORDOPARCERIADESCACRESC.CODACORDO FROM PCACORDOPARCERIADESCACRESC)) -->> Somente Acordos com Taxa
                               AND (pi_dDtBase BETWEEN TRUNC(PCACORDOPARCERIA.DTVIGENCIAINI) AND TRUNC(PCACORDOPARCERIA.DTVIGENCIAFIN))
                               AND (PCACORDOPARCERIA.CODACORDO NOT IN (SELECT PCACORDOPARCERIACLI.CODACORDO FROM PCACORDOPARCERIACLI))
                               AND (PCACORDOPARCERIA.CODACORDO NOT IN (SELECT PCACORDOPARCERIAREDECLI.CODACORDO FROM PCACORDOPARCERIAREDECLI))
                               AND (PCACORDOPARCERIA.CODACORDO NOT IN (SELECT PCACORDOPARCERIARAMOATIV.CODACORDO FROM PCACORDOPARCERIARAMOATIV))
                            ) LOOP
                               
            -- Se RegiÃ£o e Plano de Pagamento VÃ¡lidos
            IF (F_ACORDO_RESTRICAO_VALIDO(vc_Acordo.CODACORDO,
                                          pi_nNumRegiao,
                                          pi_nCodPlPag) = 'S') THEN
              -- Pesquisa Taxa para o Acordo encontrado                            
              P_OBTER_TAXA(vc_Acordo.CODACORDO,
                           pi_nCodProd,
                           po_vAchouTaxa,
                           po_nCodAcordo,
                           po_nPercTaxa,
                           po_nPerCom,
                           po_vCampo);
              -- Se Achou a Taxa
              IF (po_vAchouTaxa = 'S') THEN
                -- Sai
                EXIT;
              END IF;                                                               
            END IF;                                               
                               
          END LOOP;
        
        END IF; -- Fim CondiÃ§Ã£o: Se nÃ£o achou Acordo para o Ramo de Atividade
      
      END IF; -- Fim CondiÃ§Ã£o: Se nÃ£o achou Acordo para a Rede de Clientes    
     
    END IF; -- Fim COndiÃ§Ã£o: Se nÃ£o achou Acordo para o Cliente
      
  END P_TAXACORDOPARCERIA;
  
  /***************************************************************************************************
   Nome         : P_OBTEM_VLREPASSE
   Descricão    : Procedimento Obter o Valor do Repasse
   Parâmetros   : ENTRADA:
                  pi_vCodFilial              = Código da Filial
                  pi_nCodCli                 = Código do Cliente
                  pi_nNumRegiao              = Número da Região
                  pi_nCondVenda              = Tipo de Venda
                  pi_nCodProd                = Código do Produto
                  pi_nPrecoFabrica           = Código do Cliente
                  pi_nPrecoLiquido           = Número da Região
                  pi_vTipoAplicRepasseFilial = ParÃ¢metro da Filial
                  pi_vCriticaObrigatorio     = Se Critica obrigatoriedade
                                               (Usar no cÃ¡lculo na Venda)
                  SAIDA:
                  po_vMensagem               = Mensagem de Erro 
                  po_vTipoRepasse            = Tipo Repasse
                  po_nVlRepasse              = Valor do Repasse
   Alteração    : Anderson Silva    - 19/01/2016 - Criação da Procedure
                  Franklin Carvalho - 08/02/2016 - HIS.00211.2016 - Usar Regra de ST BCR no Repasse
                  Anderson Silva    - 16/03/2016 - Param "AS", não considerar PCTRIBUT.USABCRULTENT
                  Anderson Silva    - 04/04/2016 - 2343.032553.2016 - Verificar se tem Tributação ST para critica do Repasse
                  Anderson Silva    - 18/06/2021 - Repasse em TV5 - DDMEDICA-7380 - #VERSAO20210818A
  ***************************************************************************************************/                                       
  PROCEDURE P_OBTEM_VLREPASSE(pi_vCodFilial              IN  VARCHAR2,
                              pi_nCodCli                 IN  NUMBER,
                              pi_nNumRegiao              IN  NUMBER,
                              pi_nCondVenda              IN  NUMBER,
                              pi_nCodProd                IN  NUMBER,
                              pi_nCodSt                  IN  NUMBER,
                              pi_nPrecoFabrica           IN  NUMBER,
                              pi_nPrecoLiquido           IN  NUMBER,
                              pi_vTipoAplicRepasseFilial IN  VARCHAR2,
                              pi_vCriticaObrigatorio     IN  VARCHAR2,
                              pi_nIntegradora            IN  NUMBER,
                              pi_vOrigemPed              IN  VARCHAR2,
                              pi_vTipoFV                 IN  VARCHAR2,
                              po_vMensagem               OUT VARCHAR2,
                              po_vTipoRepasse            OUT VARCHAR2,
                              po_nVlRepasse              OUT NUMBER )
  IS
    
    -- Tipo Mercadoria do Produto
    vvTipoMerc                PCPRODUT.TIPOMERC%TYPE;
    vvUsaPmcBaseSt            PCPRODUT.USAPMCBASEST%TYPE;
    vvPercIvaBcr              PCPRODUT.PERCIVABCR%TYPE;
    -- Dados da TributaÃ§Ã£o
    vnCodSt                   PCTRIBUT.CODST%TYPE;
    vnPerDescRepasse          PCTRIBUT.PERDESCREPASSE%TYPE;
    vvUsaBcrUltEnt            PCTRIBUT.USABCRULTENT%TYPE;
    vvTIPOAPLICREPASSETRIBUT  PCTRIBUT.TIPOAPLICREPASSETRIBUT%TYPE;
    vPMC                      NUMBER;
    vvMsgPmcUf                VARCHAR2(250);    
    vnPrecoFabrica            NUMBER;
    -- ParÃ¢metros
    vvUsaTributacaoPorUf      PCCONSUM.USATRIBUTACAOPORUF%TYPE;
    vvTipoAplicRepasseFilial  PCPARAMFILIAL.VALOR%TYPE;
    vvUsaTribEntPorUf         PCCONSUM.USATRIBENTPORUF%TYPE;
    -- Dados do Cliente
    vvEstEnt                  PCCLIENT.ESTENT%TYPE;
    vvRepasse                 PCCLIENT.REPASSE%TYPE;
    vvConsumidorFinal         PCCLIENT.CONSUMIDORFINAL%TYPE;
    vnCodPraca                PCCLIENT.CODPRACA%TYPE;
    vnNumRegiao               PCREGIAO.NUMREGIAO%TYPE;
    
    -- Regra do STBCR da Integradora
    vvIntegradoraUsaBcrUltEnt PCINTEGRADORA.USABCRULTENT%TYPE;
    
    -- ExceÃ§Ã£o Tratada
    e_tratado                 EXCEPTION;
    
   /***************************************************************************
    ***************************************************************************
    **                  INICIO DO PROCESSAMENTO PRINCIPAL                    **
    ***************************************************************************                  
    ***************************************************************************/
  BEGIN
  
    -- Inicializa Retornos
    po_vTipoRepasse := NULL;
    po_nVlRepasse   := 0;
    po_vMensagem    := NULL;
    
   /*************************
    Pesquisa Dados do Produto
    *************************/
    BEGIN
      SELECT PCPRODUT.TIPOMERC
           , PCPRODUT.USAPMCBASEST
           , PCPRODUT.PERCIVABCR
        INTO vvTipoMerc
           , vvUsaPmcBaseSt
           , vvPercIvaBcr
        FROM PCPRODUT
       WHERE (PCPRODUT.CODPROD = pi_nCodProd);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vvTipoMerc     := NULL;
        vvUsaPmcBaseSt := NULL;
        vvPercIvaBcr   := NULL;
    END;
    
   /********************************************
    Se Produto e Venda que pode Calcular Repasse
    ********************************************/
    IF (vvTipoMerc IN ('M','MA','L')) AND  -->> MEDICAMENTO
       (pi_nCondVenda IN (1,5))       THEN -->> VENDA/BONIFICAÃ‡ÃƒO
  
     /*******************
      Pesquisa ParÃ¢metros
      *******************/
      
      -- PCCONSUM
      BEGIN
        SELECT NVL(USATRIBUTACAOPORUF,'N') USATRIBUTACAOPORUF
             , NVL(USATRIBENTPORUF,'N') USATRIBENTPORUF
          INTO vvUsaTributacaoPorUf
             , vvUsaTribEntPorUf
          FROM PCCONSUM;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          po_vMensagem := 'NÃ£o foram encontrados dados na PCCONSUM';
          RAISE e_tratado;
      END;
      --
      BEGIN
        SELECT NVL(USATRIBENTPORUF,'N') USATRIBENTPORUF
          INTO vvUsaTribEntPorUf
          FROM PCCONSUM;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          po_vMensagem := 'NÃ£o foram encontrados dados na PCCONSUM';
          RAISE e_tratado;
      END;
   
      -- Se passou ParÃ¢metro da Filial
      IF (TRIM(pi_vTipoAplicRepasseFilial) IS NOT NULL) THEN
        vvTipoAplicRepasseFilial := pi_vTipoAplicRepasseFilial;
      -- Se NÃƒO passou ParÃ¢metro da Filial
      ELSE
        BEGIN
          SELECT VALOR
            INTO vvTipoAplicRepasseFilial
            FROM PCPARAMFILIAL
           WHERE (CODFILIAL = pi_vCodFilial)
             AND (NOME      = 'TIPOAPLICREPASSEFILIAL');
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vvTipoAplicRepasseFilial := NULL;
        END;
      END IF;
      
      ----------------------------------------------------------------
      -- SE OPERADOR LOGÃSTICO, PRIORIZA REGRA DA INTEGRADORA DO STBCR
      ----------------------------------------------------------------
      IF ((pi_vOrigemPed = 'F') AND (NVL(pi_vTipoFV,'FV') IN ('OL','PE'))) THEN 
        BEGIN
          SELECT PCINTEGRADORA.USABCRULTENT
            INTO vvIntegradoraUsaBcrUltEnt
            FROM PCINTEGRADORA
           WHERE (PCINTEGRADORA.INTEGRADORA = pi_nIntegradora);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vvIntegradoraUsaBcrUltEnt := '0';
        END;
        -- 1 - Calcular o Repasse conforme Regra dos ParÃ¢metros da PresidÃªncia
        -- 2 - Calcular o Repasse pelo ST BCR da Ãšltima Entrada
        -- 3 - NÃ£o Calcular Repasse nos Pedidos desta Integradora
        IF    (vvIntegradoraUsaBcrUltEnt = '2') THEN
          vvTipoAplicRepasseFilial := 'AS'; -- AcrÃ©scimo ST BCR
        ELSIF (vvIntegradoraUsaBcrUltEnt = '3') THEN
          vvTipoAplicRepasseFilial := 'NA'; -- NÃ£o Aplicar
        END IF;
      END IF;          
          
     /*************************
      Pesquisa Dados do Cliente
      *************************/
      BEGIN
        SELECT PCCLIENT.ESTENT
             , NVL(PCCLIENT.REPASSE,'N') REPASSE
             , PCCLIENT.CONSUMIDORFINAL
             , PCCLIENT.CODPRACA
          INTO vvEstEnt
             , vvRepasse
             , vvConsumidorFinal
             , vnCodPraca
          FROM PCCLIENT
         WHERE (PCCLIENT.CODCLI = pi_nCodCli);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          po_vMensagem := 'NÃ£o foram encontrados dados do Cliente ' || NVL(pi_nCodCli,0);
          RAISE e_tratado;
      END;
    
     /************************************
      Pesquisa Dados do Cliente por Filial
      ************************************/
      BEGIN
        SELECT NVL(PCCLIENTFILIALMED.REPASSE,'N')
          INTO vvRepasse
          FROM PCCLIENTFILIALMED
         WHERE (PCCLIENTFILIALMED.CODCLI    = pi_nCodCli)
           AND (PCCLIENTFILIALMED.CODFILIAL = pi_vCodFilial);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -->> Se nÃ£o encontrar exceÃ§Ã£o por Filial, MantÃ©m os valores da PCCLIENT
          NULL;
      END;
      
     /**********************
      SE CLIENTE TEM REPASSE
      **********************/
      IF (vvRepasse = 'S') THEN
          
       /*******************
        Pesquisa TributaÃ§Ã£o
        *******************/
        
        -- Se passou a TributaÃ§Ã£o do ParÃ¢metro
        IF (NVL(pi_nCodSt,0) > 0) THEN
        
          -- Usa a TributaÃ§Ã£o passada no ParÃ¢metro
          vnCodSt := NVL(pi_nCodSt,0);
        
        -- Se NÃƒO passou a TributaÃ§Ã£o do ParÃ¢metro
        ELSE
              
          ---------------------------
          -- Se usa TributaÃ§Ã£o por UF
          ---------------------------
          IF (NVL(vvUsaTributacaoPorUf,'N') = 'S') THEN
          
            -- Pesquisa TributaÃ§Ã£o por UF
            BEGIN
              SELECT CODST
                INTO vnCodSt
                FROM PCTABTRIB
               WHERE (CODPROD     = pi_nCodProd)
                 AND (UFDESTINO   = vvEstEnt)
                 AND (CODFILIALNF = pi_vCodFilial);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                po_vMensagem := 'NÃ£o foi encontrada TributaÃ§Ã£o para o Produto ' || NVL(pi_nCodProd,0) || ', UF Destino [' || NVL(vvEstEnt,' ') || '] e Filial [' || NVL(pi_vCodFilial,' ' ||']');
                RAISE e_tratado;
            END;
          
          -------------------------------
          -- Se NÃƒO usa TributaÃ§Ã£o por UF
          -------------------------------
          ELSE
          
            -- Se passou a RegiÃ£o no ParÃ¢metro
            IF (NVL(pi_nNumRegiao,0) > 0) THEN
            
              vnNumRegiao := pi_nNumRegiao;
              
            -- Se NÃƒO passou a RegiÃ£o no ParÃ¢metro
            ELSE
          
              -- Pesquisa RegiÃ£o do Cliente por Filial
              BEGIN
                SELECT NUMREGIAO
                  INTO vnNumRegiao
                  FROM PCTABPRCLI
                 WHERE (CODCLI      = pi_nCodCli)
                   AND (CODFILIALNF = pi_vCodFilial);
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  vnNumRegiao := NULL;
              END;
            
              -- Se nÃ£o achou Regiao do Cliente por Filial
              IF (vnNumRegiao IS NULL) THEN
                -- Pesquisa RegiÃ£o da PraÃ§a
                BEGIN
                  SELECT NUMREGIAO
                    INTO vnNumRegiao
                    FROM PCPRACA
                   WHERE (CODPRACA = vnCodPraca);
                EXCEPTION
                 WHEN NO_DATA_FOUND THEN
                    vnNumRegiao := NULL;
                END;
              END IF;
              
            END IF; -- Fim CondiÃ§Ã£o Se passou a RegiÃ£o no ParÃ¢metro        
          
            -- Pesquisa TributaÃ§Ã£o por RegiÃ£o
            BEGIN
              SELECT CODST
                INTO vnCodSt
                FROM PCTABPR
               WHERE (CODPROD   = pi_nCodProd)
                 AND (NUMREGIAO = vnNumRegiao);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                po_vMensagem := 'NÃ£o foi encontrada TributaÃ§Ã£o para o Produto ' || NVL(pi_nCodProd,0) || ' e RegiÃ£o ' || NVL(vnNumRegiao,0);
                RAISE e_tratado;
            END;
              
          END IF; -- Fim CondiÃ§Ã£o v_usatributacaoporuf
          
        END IF; -- Fim CondiÃ§Ã£o Se passou a TributaÃ§Ã£o do ParÃ¢metro
    
       /****************************
        Pesquisa dados da TributaÃ§Ã£o
        ****************************/
        BEGIN
          SELECT PCTRIBUT.PERDESCREPASSE
               , PCTRIBUT.USABCRULTENT
               , PCTRIBUT.TIPOAPLICREPASSETRIBUT
            INTO vnPerDescRepasse
               , vvUsaBcrUltEnt
               , vvTIPOAPLICREPASSETRIBUT
            FROM PCTRIBUT 
           WHERE (CODST = vnCodSt);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            po_vMensagem := 'NÃ£o foram encontrados dados para a TributaÃ§Ã£o: ' || NVL(vnCodSt,0);
            RAISE e_tratado;
        END;     
                
       /**************************
        CALCULA O VALOR DO REPASSE
        **************************/
        IF (NVL(vvTIPOAPLICREPASSETRIBUT,'XX') <> 'XX') THEN
          vvTipoAplicRepasseFilial := vvTIPOAPLICREPASSETRIBUT;
        END IF; 
        -- Tipo de AplicaÃ§Ã£o do Repasse = AcrÃ©scimo sobre PreÃ§o Bruto
        IF (NVL(vvTipoAplicRepasseFilial,'AB') = 'AB') THEN
        
          po_nVlRepasse   := NVL(pi_nPrecoFabrica,0) * (NVL(vnPerDescRepasse,0)/100);
          po_vTipoRepasse := 'AB';
            
        -- Tipo de AplicaÃ§Ã£o do Repasse = AcrÃ©scimo ST Ult Ent.
        ELSIF  (NVL(vvTipoAplicRepasseFilial,'AB') = 'AS') THEN
        
          -- Se TributaÃ§Ã£o BCRULTENT
          IF --(NVL(vvUsaBcrUltEnt,'N') = 'S')      AND -->> Param "AS", nÃ£o considerar PCTRIBUT.USABCRULTENT
             (NVL(vvConsumidorFinal,'N') <> 'S') THEN
                      
            BEGIN
              SELECT NVL(STBCR ,0)
                INTO po_nVlRepasse
                FROM PCEST 
               WHERE (PCEST.CODPROD   = pi_nCodProd) 
                 AND (PCEST.CODFILIAL = pi_vCodFilial);
               po_vTipoRepasse := 'AS';
             EXCEPTION
               WHEN NO_DATA_FOUND THEN
                 po_nVlRepasse := 0;
             END;              
             -- Se nÃ£o achou o ST BCR e Se Validar Obrigatoriedade
             IF (NVL(po_nVlRepasse,0) <= 0)    AND
                (pi_vCriticaObrigatorio = 'S') THEN 
               -- 2343.032553.2016 - Regra EspecÃ­fica
               IF (NVL(vvUsaTribEntPorUf,'N') = 'N') AND
                  (NVL(vvUsaPmcBaseSt,'N')   <> 'S') AND -- Coloquei <> 'S' porque na base encontrei zeros no campo
                  (NVL(vvPercIvaBcr,0)        =  0 ) THEN
                 po_nVlRepasse := 0; -->> NÃƒO CORTARÃ O PRODUTO - NÃƒO TEM STBCR pela TributaÃ§Ã£o
               ELSE
                 po_vMensagem := 'Produto sem ST BCR para FormaÃ§Ã£o do Repasse';
                 RAISE e_tratado;
               END IF;
             END IF;
                    
          END IF; -- Fim CondiÃ§Ã£o Se TributaÃ§Ã£o BCRULTENT
            
        -- Tipo de AplicaÃ§Ã£o do Repasse = AcrÃ©scimo sobre PreÃ§o LÃ­quido
        ELSIF (NVL(vvTipoAplicRepasseFilial,'AB') = 'AL') THEN
    
          po_nVlRepasse   := NVL(pi_nPrecoLiquido,0) *  (NVL(vnPerDescRepasse,0)/100);
          po_vTipoRepasse := 'AL';
        
        ELSIF (NVL(vvTipoAplicRepasseFilial,'AB') = 'AP') THEN
          P_OBTEM_PMC_PRODUTO(pi_vCodFilial,
                              pi_nCodProd,
                              vvEstEnt,
                              pi_nNumRegiao, 
                              vPMC, 
                              vnPrecoFabrica,   
                              vvMsgPmcUf);      
          po_nVlRepasse   := vPMC * NVL(vnPerDescRepasse,0) / 100;
          po_vTipoRepasse := 'AP';   
        END IF; 
        
        -- Arredonda para 6 Casas
        po_nVlRepasse := ROUND(po_nVlRepasse,6);
        
      END IF; -- Fim CondiÃ§Ã£o SE CLIENTE TEM REPASSE
    
    END IF; -- Fim CondiÃ§Ã£o Se Produto e Venda que pode Calcular Repasse
                                                             
  EXCEPTION
    WHEN e_tratado THEN
      -- Sem ST
      po_vTipoRepasse := NULL;
      po_nVlRepasse   := 0;
    WHEN OTHERS THEN  
      -- Sem ST
      po_vTipoRepasse := NULL;
      po_nVlRepasse   := 0;
      po_vMensagem    := 'Erro CÃ¡lculo Repasse: ' || SUBSTR('Erro: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ' >> ' || SQLERRM,1,240);
  END P_OBTEM_VLREPASSE;
                                  
  /*******************************************************************************
   Nome         : P_OBTEM_PMC_PRODUTO
   Descricão    : Procedimento Obter o PMC do Produto
   Parâmetros   : ENTRADA:
                  pi_vCodFilial = Código da Filial
                  pi_nCodProd   = Código do Produto
                  pi_vUfCliente = UF do Cliente
                  pi_nRegiao    = Região
                  SAIDA:
                  po_nPmc          = Valor do PMC
                  po_nPrecoFabrica = Preço Fábrica
                  po_vMensagem     = Mensagem de Erro
   Alteracão    : Anderson Silva - 10/04/2014 - Criação da Procedure
   Alteracão    : Anderson Silva - 30/04/2014 - Alteração Tipo Variável de pi_vCodFilial
   Alteracão    : Anderson Silva - 28/12/2015 - HIS.04408.2015 - Alteração Preço Fábrica por UF
  ********************************************************************************/                                       
  PROCEDURE P_OBTEM_PMC_PRODUTO(pi_vCodFilial    IN  VARCHAR2,
                                pi_nCodProd      IN  NUMBER,
                                pi_vUfCliente    IN  VARCHAR2,
                                pi_nRegiao       IN  NUMBER,
                                po_nPmc          OUT NUMBER,
                                po_nPrecoFabrica OUT NUMBER,
                                po_vMensagem     OUT VARCHAR2,
                                pi_nCodCli       IN  NUMBER DEFAULT NULL)
  IS
  
    -- Parâmetros
    vvUsaPmcUf                   PCPARAMFILIAL.VALOR%TYPE;
    vvUtilizaPrecoFabricaPorUf   PCPARAMFILIAL.VALOR%TYPE;
    -- Identificador de Região Zona Franca de Manaus
    vvRegiaoZfm                  PCREGIAO.REGIAOZFM%TYPE;
    -- Preços Nacionais por Produto
    TYPE TRecNacionalPorProduto   IS RECORD(
         vnPmc                    PCPRODUT.PRECOMAXCONSUM%TYPE,
         vnPrecoFabrica           PCPRODUT.CUSTOREP%TYPE);
    vrNacionalPorProduto          TRecNacionalPorProduto;   
    -- Preços Zona Franca por Produto
    TYPE TRecZonaFrancaPorProduto IS RECORD(
         vnPmc                    PCPRODUT.PRECOMAXCONSUM%TYPE,
         vnPrecoFabrica           PCPRODUT.CUSTOREP%TYPE);
    vrZonaFrancaPorProduto        TRecZonaFrancaPorProduto;  
    -- Preços Nacionais por UF
    TYPE TRecNacionalPorUf        IS RECORD(
         vnPmc                    PCTABMEDABCFARMA.PRECOMAXCONSUM%TYPE,
         vnPrecoFabrica           PCTABMEDABCFARMA.PRECOFABRICA%TYPE);
    vrNacionalPorUf               TRecNacionalPorUf;
    -- Preços Zona Franca por UF
    TYPE TRecZonaFrancaPorUf      IS RECORD(
         vnPmc                    PCTABMEDABCFARMA.PRECOMAXCONSUM%TYPE,
         vnPrecoFabrica           PCTABMEDABCFARMA.PRECOFABRICA%TYPE);
    vrZonaFrancaPorUf             TRecZonaFrancaPorUf;
    
    -- Tipo Cliente - DDVENDAS-35830
    vvTipoCliMed                  PCCLIENT.TIPOCLIMED%TYPE;
    -- Convênio - DDVENDAS-35830
    vvConvenioIsencaoIcmsMed      PCPRODUT.CONVENIOISENCAOICMSMED%TYPE;
    
  /*********************************
   INICIO DO PROCESSAMENTO PRINCIPAL  
   *********************************/
  BEGIN
  
    -- Inicializa Retornos
    po_nPmc      := 0;
    po_vMensagem := NULL;
  
   /***************************************
    Utilizando as Exceções - DDVENDAS-35830
    ***************************************/
	
	      -- Preço Fábrica por UF
    BEGIN
      SELECT NVL(VALOR,'N') VALOR
        INTO vvUtilizaPrecoFabricaPorUf
        FROM PCPARAMFILIAL
       WHERE (CODFILIAL = '99')
         AND (NOME      = 'UTILIZAPRECOFABRICAPORUF');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vvUtilizaPrecoFabricaPorUf := 'N';
    END; 
    
	IF NVL(vvUtilizaPrecoFabricaPorUf, 'N') = 'S' THEN
	
      IF (NVL(pi_nCodCli,0) > 0) THEN
      
        -- Tipo Cliente
        BEGIN
          SELECT TIPOCLIMED
            INTO vvTipoCliMed 
            FROM PCCLIENT
           WHERE (CODCLI = pi_nCodCli);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vvTipoCliMed := NULL;
        END;
	 
	   END IF;
      
      -- Convênio
      BEGIN
        SELECT NVL(CONVENIOISENCAOICMSMED,'N')
          INTO vvConvenioIsencaoIcmsMed
          FROM PCPRODUT
         WHERE (CODPROD = pi_nCodProd);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vvConvenioIsencaoIcmsMed := 'N';
      END;
      
      -- Verifica seRegião ZFM
      BEGIN
        SELECT NVL(PCREGIAO.REGIAOZFM,'N') REGIAOZFM
          INTO vvRegiaoZfm
          FROM PCREGIAO
         WHERE (PCREGIAO.NUMREGIAO = pi_nRegiao);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vvRegiaoZfm := 'N';
      END;
      
      -- Se Tabela Região Zona Franca
      IF (NVL(vvRegiaoZfm,'N') = 'S') THEN

        po_nPmc          := F_OBTEM_PRECO_ABCFARMA('PMC',
                                                   pi_nCodProd,
                                                   'ZF',
                                                   pi_vCodFilial,
                                                   pi_vCodFilial,
                                                   pi_nRegiao,
                                                   vvTipoCliMed,
                                                   vvConvenioIsencaoIcmsMed);
      
        po_nPrecoFabrica := F_OBTEM_PRECO_ABCFARMA('PF',
                                                   pi_nCodProd,
                                                   'ZF',
                                                   pi_vCodFilial,
                                                   pi_vCodFilial,
                                                   pi_nRegiao,
                                                   vvTipoCliMed,
                                                   vvConvenioIsencaoIcmsMed);
      
      -- Se Tabela Nacional
      ELSE
      
        po_nPmc          := F_OBTEM_PRECO_ABCFARMA('PMC',
                                                   pi_nCodProd,
                                                   pi_vUfCliente,
                                                   pi_vCodFilial,
                                                   pi_vCodFilial,
                                                   pi_nRegiao,
                                                   vvTipoCliMed,
                                                   vvConvenioIsencaoIcmsMed);
      
        po_nPrecoFabrica := F_OBTEM_PRECO_ABCFARMA('PF',
                                                   pi_nCodProd,
                                                   pi_vUfCliente,
                                                   pi_vCodFilial,
                                                   pi_vCodFilial,
                                                   pi_nRegiao,
                                                   vvTipoCliMed,
                                                   vvConvenioIsencaoIcmsMed);
      
      END IF;
            
    ELSE
  
     /**********
      Parâmetros
      **********/
      
      -- PMC por UF
      BEGIN
        SELECT NVL(VALOR,'N') VALOR
          INTO vvUsaPmcUf
          FROM PCPARAMFILIAL
         WHERE (CODFILIAL = '99')
           AND (NOME      = 'UTILIZAPMCUF');
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vvUsaPmcUf := 'N';
      END;                 
    
     /**********
      Região ZFM
      **********/
        
      -- Pesquisa Região - HIS.04408.2015
      BEGIN
        SELECT NVL(PCREGIAO.REGIAOZFM,'N') REGIAOZFM
          INTO vvRegiaoZfm
          FROM PCREGIAO
         WHERE (PCREGIAO.NUMREGIAO = pi_nRegiao);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vvRegiaoZfm := 'N';
      END;
        
      -----------------------
      -- Se Usa PMC por UF
      -- OU 
      -- Preço Fábrica por UF
      -----------------------
      IF (NVL(vvUsaPmcUf,'N')        = 'S') OR
         (vvUtilizaPrecoFabricaPorUf = 'S') THEN
         
        -- Se ZFM - Zona Franca Manaus
        IF (vvRegiaoZfm = 'S') THEN
          -- Pesquisa PMC e Preço por UF - Zona Franca Manaus
          BEGIN
            SELECT NVL(PRECOMAXCONSUM,0) PRECOMAXCONSUM
                 , NVL(PRECOFABRICA,0)   PRECOFABRICA
              INTO vrZonaFrancaPorUf.vnPmc
                 , vrZonaFrancaPorUf.vnPrecoFabrica
              FROM PCTABMEDABCFARMA
             WHERE (CODPROD = pi_nCodProd)
               AND (UF      = 'ZF');
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vrZonaFrancaPorUf.vnPmc          := 0;
              vrZonaFrancaPorUf.vnPrecoFabrica := 0;
          END;
        END IF;  
         
        -- Pesquisa PMC por UF do Cliente
        BEGIN
          SELECT NVL(PRECOMAXCONSUM,0) PRECOMAXCONSUM
               , NVL(PRECOFABRICA,0)   PRECOFABRICA
            INTO vrNacionalPorUf.vnPmc
               , vrNacionalPorUf.vnPrecoFabrica
            FROM PCTABMEDABCFARMA
           WHERE (CODPROD = pi_nCodProd)
             AND (UF      = pi_vUfCliente);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vrNacionalPorUf.vnPmc          := 0;
            vrNacionalPorUf.vnPrecoFabrica := 0;
        END;
        
      END IF;    
      
      ----------------------------------
      -- PMC e Preço Fábrica da PCPRODUT
      ----------------------------------
        
      -- Pesquisa PMC e Preço Fábrica do Produto NACIONAL e ZFM
      BEGIN
        SELECT NVL(PRECOMAXCONSUM,0)
             , NVL(CUSTOREP,0)
             , NVL(PRECOMAXCONSUMZFM,0)
             , NVL(CUSTOREPZFM,0)         
          INTO vrNacionalPorProduto.vnPmc
             , vrNacionalPorProduto.vnPrecoFabrica
             , vrZonaFrancaPorProduto.vnPmc
             , vrZonaFrancaPorProduto.vnPrecoFabrica
          FROM PCPRODUT
         WHERE (CODPROD = pi_nCodProd);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vrNacionalPorProduto.vnPmc             := 0;
          vrNacionalPorProduto.vnPrecoFabrica    := 0;
          vrZonaFrancaPorProduto.vnPmc          := 0;
          vrZonaFrancaPorProduto.vnPrecoFabrica := 0;
      END;
            
     /****************
      Definição do PMC
      ****************/
      
      ----------------------------------------------------
      -- PMC POR UF - Tabela PCTABMEDABCFARMA ------------
      ----------------------------------------------------
      IF (NVL(vvUsaPmcUf,'N')                 = 'S') OR
         (NVL(vvUtilizaPrecoFabricaPorUf,'N') = 'S') THEN
    
        -- Inicializa PMC com Valor da UF do Cliente
        po_nPmc := vrNacionalPorUf.vnPmc;
        
        -- Substitui PMC com Valor da Zona Franca se a Região for ZFM
        IF (vvRegiaoZfm = 'S') AND
           (NVL(vrZonaFrancaPorUf.vnPmc,0) > 0) THEN
          po_nPmc := vrZonaFrancaPorUf.vnPmc;       
        END IF;    
         
      ----------------------------------------------------
      -- PMC POR PRODUTO ---------------------------------
      ----------------------------------------------------
      ELSE
    
        -- Inicializa PMC com Valor Nacional da PCPRODUT
        po_nPmc := vrNacionalPorProduto.vnPmc;
     
        -- Substitui PMC com Valor da Zona Franca se a Região for ZFM
        IF (vvRegiaoZfm = 'S')   AND
           (NVL(vrZonaFrancaPorProduto.vnPmc,0) > 0) THEN
          po_nPmc := vrZonaFrancaPorProduto.vnPmc;       
        END IF;
      
      END IF;     
    
     /**************************
      Definição do Preço Fábrica
      **************************/
      
      ----------------------------------------------------
      -- PREÇO FÁBRICA POR UF - Tabela PCTABMEDABCFARMA --
      ----------------------------------------------------
      IF (NVL(vvUtilizaPrecoFabricaPorUf,'N') = 'S') THEN
    
        -- Inicializa Preço Fábrica com Valor da UF do Cliente
        po_nPrecoFabrica := vrNacionalPorUf.vnPrecoFabrica;
     
        -- Substitui Preço Fábrica com Valor da Zona Franca se a Região for ZFM
        IF (vvRegiaoZfm = 'S')   AND
           (NVL(vrZonaFrancaPorUf.vnPrecoFabrica,0) > 0) THEN
          po_nPrecoFabrica := vrZonaFrancaPorUf.vnPrecoFabrica;       
        END IF;
      
      ----------------------------------------------------
      -- PREÇO FÁBRICA POR PRODUTO -----------------------
      ----------------------------------------------------
      ELSE
    
        -- Inicializa Preço Fábrica com Valor Nacional da PCPRODUT
        po_nPrecoFabrica := vrNacionalPorProduto.vnPrecoFabrica;
     
        -- Substitui Preço Fábrica com Valor da Zona Franca se a Região for ZFM
        IF (vvRegiaoZfm = 'S')   AND
           (NVL(vrZonaFrancaPorProduto.vnPrecoFabrica,0) > 0) THEN
          po_nPrecoFabrica := vrZonaFrancaPorProduto.vnPrecoFabrica;
        END IF;
      
      END IF;
            
    END IF; -- Fim Condição: Usando as Exceções
    
  EXCEPTION
    WHEN OTHERS THEN
      po_vMensagem := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ' >> ' || SQLERRM;
  END P_OBTEM_PMC_PRODUTO;

 /*******************************************************************************
  Nome         : P_OBTER_VALORES_BENEF_FISCAIS
  Descricão    : Procedimento Obter os valores dos Descontos dos Benefícios 
                 Fiscais: 
                 - SUFRAMA
                 - DESONERAÇÃO ICMS
                 - Redução PIS e COFINS
  Solicitação  : DDMEDICA-7594                
  *******************************************************************************/
  PROCEDURE P_OBTER_VALORES_BENEF_FISCAIS(pi_vCodFilial               IN VARCHAR2,
                                          pi_vCodFilialNf             IN VARCHAR2,
                                          pi_nCodCli                  IN NUMBER,
                                          pi_nCodProd                 IN NUMBER,
                                          pi_nCodSt                   IN NUMBER,
                                          pi_nNumCasasDecVenda        IN NUMBER,
                                          pi_vTipoCalcSuframa         IN VARCHAR2,
                                          pi_nPerDescIsencaoIcmsTrib  IN NUMBER,
                                          pi_vAplicaDescIsencaoMed    IN VARCHAR2,
                                          pi_nPVendaSemImposto        IN NUMBER,
                                          pi_nPTabelaSemImposto       IN NUMBER,
                                          pi_nPBaseRcaSemImposto      IN NUMBER,
                                          pi_nQt                      IN NUMBER,                                          
                                          po_nVlDescReducaoPis       OUT NUMBER,
                                          po_nPercDescReducaoPis     OUT NUMBER,
                                          po_nVlDescReducaoCofins    OUT NUMBER,
                                          po_nPercDescReducaoCofins  OUT NUMBER,
                                          po_nVlDescIcmIsencao       OUT NUMBER,
                                          po_nPercDescIcmIsencao     OUT NUMBER,
                                          po_nVlDescSuframa          OUT NUMBER,
                                          po_nPercDescSuframa        OUT NUMBER,
                                          po_nNovoPVenda             OUT NUMBER,
                                          po_nNovoPTabela            OUT NUMBER,
                                          po_nNovoPBaseRca           OUT NUMBER,
                                          po_vErros                  OUT VARCHAR2,
                                          po_vMsgErros               OUT VARCHAR2,
                                          pi_vCalcSomenteDesoneracao  IN VARCHAR2 DEFAULT 'N') IS
    vnQtde NUMBER;  
    vCALCDESONERACAOFATMEDICAM PCPARAMFILIAL.VALOR%TYPE; -- DDVENDAS-37241
    vnBaseCalcDescPisCofinsIcms PCTABPR.PTABELA%TYPE; -- DDVENDAS-37241
  BEGIN
   
    ------------------------------------------------------------------------------
    -- Inicializa Retornos ------------------------------------------------------
    ------------------------------------------------------------------------------
    po_nVlDescReducaoPis      := 0;
    po_nPercDescReducaoPis    := 0;
    po_nPercDescReducaoCofins := 0;
    po_nVlDescSuframa         := 0;
    po_nPercDescSuframa       := 0;
    po_nVlDescIcmIsencao      := 0;
    po_nPercDescIcmIsencao    := 0;
    po_nNovoPVenda            := pi_nPVendaSemImposto;
    po_nNovoPTabela           := pi_nPTabelaSemImposto;
    po_nNovoPBaseRca          := pi_nPBaseRcaSemImposto;
    po_vErros                 := 'N';
    po_vMsgErros              := NULL;
    ------------------------------------------------------------------------------
    
    -- Quantidade para Arredondamento da Desoneração ICMS e SUFRAMA
    vnQtde := pi_nQt;
    IF (NVL(pi_nQt,0) = 0) THEN
      vnQtde := 1;
    END IF;
    
    -- Parâmetro - DDVENDAS-37241
    PROC_PCPARAMFILIAL('99',
                       'CALCDESONERACAOFATMEDICAM',
                       'N',
                       vCALCDESONERACAOFATMEDICAM);
                       
    ------------------------------------------------------------------------------
    -- BASE DE CÁLCULO DOS DESCONTOS DE PIS, COFINS E ICMS (PLiq. Sem Impostos) --
    ------------------------------------------------------------------------------
  
    vnBaseCalcDescPisCofinsIcms := NVL(pi_nPVendaSemImposto,0);
  
    --------------------------------------------------------------------------
    -- DDVENDAS-37241 - Se a Desoneração for calculada somente no Faturamento,
    --                  o Preço da Precificação está desonerado, então precisa
    --                  elevá-lo para calcular o desconto de isenção de ICMS
    --------------------------------------------------------------------------
    
    IF (NVL(vCALCDESONERACAOFATMEDICAM,'N') = 'S') THEN
    
      -- ELEVA O PREÇO COM O VALOR DESCONTADO DA DESONERAÇÃO
      
      IF (NVL(pi_nPerDescIsencaoIcmsTrib,0) > 0) THEN
      
        vnBaseCalcDescPisCofinsIcms := ROUND(NVL(vnBaseCalcDescPisCofinsIcms,0) / (1 - (nvl(pi_nPerDescIsencaoIcmsTrib,0) / 100)),pi_nNumCasasDecVenda);
      
      END IF;
        
    END IF;
  
    ------------------------------------------------------------------------------
    -- CALCULA DESCONTOS DE BENEFICIOS FISCAIS CONFORME REGRA PACOTE -------------
    ------------------------------------------------------------------------------
    
    P_CALC_DESC_PIS_COFINS_ICMS(pi_vCodFilial,
                                pi_vCodFilialNf,
                                NULL,                        -->> Não tem Implementação de Filial Retira
                                pi_nCodCli,
                                pi_nCodProd,
                                vnBaseCalcDescPisCofinsIcms, -->> Base de Cálculo
                                po_nVlDescReducaoPis,
                                po_nPercDescReducaoPis,
                                po_nVlDescReducaoCofins,
                                po_nPercDescReducaoCofins,
                                po_nVlDescIcmIsencao,
                                po_nPercDescIcmIsencao,
                                po_nVlDescSuframa,
                                po_nPercDescSuframa,
                                po_vErros,
                                po_vMsgErros);
    
    
    ------------------------------------------------------------------------------
    -- ESPECIFICO MEDICAMENTOS - SUFRAMA -----------------------------------------
    ------------------------------------------------------------------------------

    -- Arredondamento do Desconto de SUFRAMA
    IF (F_ARREDONDAMENTO_SUFRAMA(po_nVlDescSuframa,pi_nNumCasasDecVenda,pi_vTipoCalcSuframa) <> 0) THEN
      po_nVlDescSuframa := F_ARREDONDAMENTO_SUFRAMA(po_nVlDescSuframa,pi_nNumCasasDecVenda,pi_vTipoCalcSuframa);
    END IF;
      
    ------------------------------------------------------------------------------
    -- ESPECIFICO MEDICAMENTOS - DESONERACAO -------------------------------------
    ------------------------------------------------------------------------------
    
    -- Calcula Desconto Isenção conforme parâmetros de cliente e tributação
    IF (NVL(pi_vAplicaDescIsencaoMed,'N') = 'S') THEN
      po_nVlDescIcmIsencao   := NVL(vnBaseCalcDescPisCofinsIcms,0) * (NVL(pi_nPerDescIsencaoIcmsTrib,0) / 100);
      po_nPercDescIcmIsencao := pi_nPerDescIsencaoIcmsTrib;
    END IF;

    -- Se o Valor Total do Desconto de Isenção de ICMS tender a zero, aredonda o Valor Unitário do Suframa para as casas decimais do preço de venda
    IF (NVL(po_nVlDescIcmIsencao,0) > 0) THEN
      IF (F_ARREDONDAMENTO_DESONERACAO((po_nVlDescIcmIsencao * NVL(vnQtde,0)),2,'N',pi_nCodSt) = 0) THEN
        po_nVlDescIcmIsencao := F_ARREDONDAMENTO_DESONERACAO(po_nVlDescIcmIsencao,pi_nNumCasasDecVenda,'S',pi_nCodSt);
      END IF;
    END IF;
    
    ---------------------------------------------------------------------------
    -- DDVENDAS-37241 - Remoção do valor do desconto do ICMS para não desonerar
    --                  novamente o Produto, que já foi Precificado desonerado
    ---------------------------------------------------------------------------
    
    IF (NVL(vCALCDESONERACAOFATMEDICAM,'N') = 'S') THEN

      -- Exceto Cálculo do ST e da Desoneração do Faturamento, onde deve retornar o valor da desoneração
      IF (NVL(pi_vCalcSomenteDesoneracao,'N') <> 'S') THEN
       
        po_nVlDescIcmIsencao   := 0;
        po_nPercDescIcmIsencao := 0;
        
      END IF;
      
      ----------------------------------------------------------------------------------
      -- Aplicação dos Descontos dos Benefícios Fiscais nos Preços EXCETO DESONERAÇÃO --
      ----------------------------------------------------------------------------------
      po_nNovoPVenda          := ROUND(NVL(po_nNovoPVenda,0)
                                     - NVL(po_nVlDescReducaoPis,0)
                                     - NVL(po_nVlDescReducaoCofins,0)
                                     - NVL(po_nVlDescSuframa,0)
                                     , pi_nNumCasasDecVenda);
      po_nNovoPTabela         := ROUND(NVL(po_nNovoPTabela,0)
                                     - NVL(po_nVlDescReducaoPis,0)
                                     - NVL(po_nVlDescReducaoCofins,0)
                                     - NVL(po_nVlDescSuframa,0)
                                     , pi_nNumCasasDecVenda);
      po_nNovoPBaseRca        := ROUND(NVL(po_nNovoPBaseRca,0)
                                     - NVL(po_nVlDescReducaoPis,0)
                                     - NVL(po_nVlDescReducaoCofins,0)
                                     - NVL(po_nVlDescSuframa,0)
                                     , pi_nNumCasasDecVenda);      
      
    ELSE   
    
      ------------------------------------------------------------------------------
      -- Aplicação dos Descontos dos Benefícios Fiscais nos Preços -----------------
      ------------------------------------------------------------------------------    
      po_nNovoPVenda          := ROUND(NVL(po_nNovoPVenda,0)
                                     - NVL(po_nVlDescReducaoPis,0)
                                     - NVL(po_nVlDescReducaoCofins,0)
                                     - NVL(po_nVlDescIcmIsencao,0)
                                     - NVL(po_nVlDescSuframa,0)
                                     , pi_nNumCasasDecVenda);
      po_nNovoPTabela         := ROUND(NVL(po_nNovoPTabela,0)
                                     - NVL(po_nVlDescReducaoPis,0)
                                     - NVL(po_nVlDescReducaoCofins,0)
                                     - NVL(po_nVlDescIcmIsencao,0)
                                     - NVL(po_nVlDescSuframa,0)
                                     , pi_nNumCasasDecVenda);
      po_nNovoPBaseRca        := ROUND(NVL(po_nNovoPBaseRca,0)
                                     - NVL(po_nVlDescReducaoPis,0)
                                     - NVL(po_nVlDescReducaoCofins,0)
                                     - NVL(po_nVlDescIcmIsencao,0)
                                     - NVL(po_nVlDescSuframa,0)
                                     , pi_nNumCasasDecVenda);
    
    END IF;
                                         
  EXCEPTION
    WHEN OTHERS THEN
      po_vErros    := 'S';
      po_vMsgErros := 'Erro no cálculo dos benefícios fiscais (PKG_MEDICAMENTOS): ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ' >>' || SQLERRM; 
  END P_OBTER_VALORES_BENEF_FISCAIS;                                          

  /*******************************************************************************
   Nome         : P_OBTEM_STFONTE_40
   Descricão    : Procedimento Obter a Base e Valor do ST Fonte por Preço de 
                  Tabela ou Preço de Venda
   Parâmetros   : ENTRADA:
                  pi_vCodFilial            = Código da Filial
                  pi_nCodProd              = Código do Produto
                  pi_nCodCli               = Código do Cliente
                  pi_nNumRegiao            = Número da Região
                  pi_nCondVenda            = Tipo de Venda
                  pi_nPercVenda            = Percentual de Venda do Pedido
                  pi_vPVenda               = Preço de Venda
                  pi_nValorIpi             = Valor do Ipi                
                  pi_nPrecoMaxConsum       = Preço Max. Consumidor
                  pi_nValorUltEnt          = Valor Últ. Entrada
                  pi_nCustoNfSemSt         = Custo NF sem ST
                  pi_nPTabela              = Preço de Tabela
                  pi_vSomenteIVATribut     = 'N' em todas as chamadas exceto no 
                                                 Simples Nacional
                  pi_vPesquisarCustos      = S - Pesquisa Custos na PCEST
                                             N - Não pesquisa Custos na PCEST, 
                                                 usa os passados nos parâmetros
                  pi_vItemBonific          = S/N
                  pi_nVlFreteOutrasDesp    = Quando chamado da Package Faturamento,
                                             para ratear o Frete e Outras Despesas na
                                             Base de ST  
                  pi_vTipoChamada          = Determina o tipo de chamada da função 
                                             'F' - Chamado do Faturamento
                                             'L' - Chamado do Cálculo do ST Especial
                                                   de Operador Logísitco - HIS.01858.2015                                          
                  pi_nCodFilialNf          = Código Filial NF                           
                  ENTRADA E SAIDA:
                  pio_nCodSt               = Código da Tributação
                  SAIDA:
                  po_nBaseStFonte          = Base do ST Fonte
                  pi_nValorIpi             = Valor do ST Fonte
                  po_vMensagem             = Mensagem de Erro se ouver
                  po_vRegimeEspIsenStFonte = Se Isento de ST Fonte S/N
                  po_nPautaFonte           = Valor de Pauta ST Fonte (Farmacia Popular)
                  po_vObservacaoStFonte    = Log de Cálculo
                  po_vIndEscalaRelevante   = Escala Relevante ou Não Relevante (S/N)
                  po_vCnpjFabricante       = CNPJ Fabricante
                  po_vFabricante           = Fabricante
                  po_nVLBASEFCPICMS        =  -- HIS.04200.2017
                  po_nVLBASEFCPST          =  -- HIS.04200.2017
                  po_nVLBCFCPSTRET         =  -- HIS.04200.2017
                  po_nPERFCPSTRET          =  -- HIS.04200.2017
                  po_nVLFCPSTRET           =  -- HIS.04200.2017
                  po_nPERFCPSN             =  -- HIS.04200.2017
                  po_nVLFECP               =  -- HIS.04200.2017
                  po_nVLACRESCIMOFUNCEP    =  -- HIS.04200.2017
                  po_nPERACRESCIMOFUNCEP   =  -- HIS.04200.2017
                  po_nALIQICMSFECP         =  -- HIS.04200.2017
                  po_nVLCREDFCPICMSSN      =  -- HIS.04200.2017      
                  po_nCODCONFIGFUNCEPMED          
                  pi_vOrdemCalculo         = P - Padrão
                                           = I - Inverso
                  pi_vMemoriaCalculo       = S - Sim (Grava a Memória de Cálculo
                                             N - Não (Não grava a Memória de Cálculo)
                  pi_nValorNotaFiscal      = Valor da Nota Fiscal           
   Alteração    : Anderson Silva - 27/08/2014 - [HIS.03151.2014] Criação da Procedure
   Alteração    : Anderson Silva - 23/09/2014 - [0.107160.2014] Usar PTabela na Base da Aliq. 2
   Alteração    : Anderson Silva - 08/01/2015 - Merge ST por Preço de Tabela
   Alteracão    : Anderson Silva - 08/01/2015 - Simples Nacional [HIS.05161.2014]
   Alteracão    : Anderson Silva - 21/01/2015 - Parâmetros ST do Cliente por Filial
   Alteracão    : Anderson Silva - 26/01/2015 - CAT CMED [HIS.00021.2015]
                                                Regime Isenção [HIS.04991.2014]
   Alteração    : Anderson Silva - 05/02/2015 - Bonificação não calcula ICMS    
   Alteração    : Anderson Silva - 08/04/2015 - 4663.042313.2015 - Somar Despesas Base 2 do ST                                           
   Alteração    : Rubens Junior  - 24/04/2015 - HIS.00679.2015 - ST PEPS
   Alteração    : Anderson Silva - 25/04/2015 - HIS.00679.2015 - ST PEPS 
                                                Ajuste Ordenação por Data + NumTransEnt
   Alteração    : Anderson Silva - 25/06/2015 - Ajuste ST sobre PTABELA
   Alteração    : Anderson Silva - 01/07/2015 - HIS.01858.2015 - Somar ST no PVENDA no Pedido de OL em clientes Não Fonte v2
   Alteração    : Anderson Silva - 17/07/2015 - HIS.03187.2015 - Cálculo ST pelo Regime Simplificado de Carga Tributária
   Alteração    : Anderson Silva - 23/11/2015 - HIS.03788.2015 - Regra do USABCRULTENT tem que ficar dentro do STFONTE por causa do Repasse por STBCR
   Alteração    : Anderson Silva - 28/12/2015 - HIS.04408.2015 - Preço Fábrica/PMC por UF
   Alteração    : Franklin Carvalho - 13/04/2016 - HIS.04322.2015 - Substituição Tributária Fonte X Simples Nacional
   Alteração    : Anderson Silva - 01/07/2016 - 4415.073219.2016 - ST Fonte TV10
   Alteração    : Franklin Carvalho - 06/07/2016 - Não Calcular ST Fonte se valores não informados na Tributação
   Alteração    : Anderson Silva - 21/10/2016 - Regra ST Paraná
   Alteração    : Anderson Silva - 06/01/2017 - 5661.146071.2016 - Redutor CAT-49/2016
   Alteração    : Anderson Silva - 25/04/2017 - HIS.01277.2017 - Carga Mínima Deferimento ST 
   Alteração    : Anderson Silva - 27/04/2017 - HIS.01277.2017 - observar valor st < % carga mínima
   Alteração    : Anderson Silva - 08/06/2017 - HIS.01838.2017 - MODALIDADE DE DETERMINAÇÃO DA BASE DE CÁLCULO DO ICMS ST
   Alteração    : Anderson Silva - 14/09/2017 - HIS.03371.2017 - Escala Relevante e não Relevante
   Alteração    : Anderson Silva - 21/09/2017 - HIS.03371.2017 - Stfonte carga trib. média
   Alteração    : Anderson Silva - 06/10/2017 - HIS.03428.2017 - CONFORME NOVA LEGISLAÇÃO, SEMPRE SOMARÁ NO ICMS PRÓPRIO AS OUTRAS DESPESAS 
   Alteração    : Anderson Silva - 09/11/2017 - HIS.04200.2017 - ST FUNCEP
   Alteração    : Anderson Silva - 11/01/2018 - HIS.04200.2017 - PCTRIBUT.CODCONFIGFUNCEPMED
   Alteração    : Anderson Silva - 19/04/2018 - MED-1080 - Redução Base Crédito ST
   Alteração    : Anderson Silva - 20/05/2018 - Cálculo ST Inverso
                                                -- A memória de Cálculo desta condição foi colocada na linha MC001
   Alteração    : Anderson Silva - 20/06/2018 - MED-1090 - FCP
   Alteração    : Anderson Silva - 02/08/2018 - MED-1471 - Alteração ST Funcep TV10
   Alteração    : Anderson Silva - 21/11/2018 - Merge ST Reverso Base Reduzida
   Alteração    : Anderson Silva - 29/01/2019 - MED-1930 - ST inverso FECP
   Alteração    : Anderson Silva - 20/03/2019 - MED-2346 - Novo Cálculo FECP
   Alteração    : Anderson Silva - 04/04/2019 - MED-2425 - Alteração cálculo resultado FECP negativo
   Alteração    : Anderson Silva - 17/05/2019 - MED-2521 - Isenção ST Bonificação
   Alteração    : Anderson Silva - 05/07/2019 - DDMEDICA-198 - Item Bonificado
   Alteração    : Anderson Silva - 04/11/2019 - ST para Pedido Avaria
  **********************************************************************************/                                       
  PROCEDURE P_OBTEM_STFONTE_40(pi_vCodFilial             IN VARCHAR2,
                               pi_nCodProd               IN NUMBER,
                               pi_nCodCli                IN NUMBER,
                               pi_nNumRegiao             IN NUMBER,
                               pi_nCondVenda             IN NUMBER,
                               pi_nPercVenda             IN NUMBER,
                               pio_nCodSt                IN OUT NUMBER,
                               pi_vPVenda                IN NUMBER,
                               pi_nValorIpi              IN NUMBER,                                
                               pi_nPrecoMaxConsum        IN NUMBER,
                               pi_nValorUltEnt           IN NUMBER,
                               pi_nCustoNfSemSt          IN NUMBER,
                               pi_nPTabela               IN NUMBER,
                               pi_vSomenteIVATribut      IN VARCHAR2,
                               pi_vPesquisarCustos       IN VARCHAR2,
                               pi_vItemBonific           IN VARCHAR2,
                               pi_nVlFreteOutrasDesp     IN NUMBER,
                               po_nBaseStFonte          OUT NUMBER,
                               po_nValorStFonte         OUT NUMBER,
                               po_vMensagem             OUT VARCHAR2,
                               po_vRegimeEspIsenStFonte OUT VARCHAR2,
                               po_nAliqIcms1            OUT NUMBER,
                               po_nAliqIcms2            OUT NUMBER,
                               po_nIva                  OUT NUMBER,
                               po_nPercBaseRedStFonte   OUT NUMBER,
                               pi_vTipoChamada           IN VARCHAR2 DEFAULT 'O',
                               pi_nQT                    IN NUMBER DEFAULT 0,
                               pi_nNumPedido             IN NUMBER DEFAULT NULL,
                               pi_nCodFilialNf           IN VARCHAR2,
                               po_nPautaFonte           OUT NUMBER,
                               po_vObservacaoStFonte    OUT VARCHAR2,
                               po_vIndEscalaRelevante   OUT VARCHAR2,
                               po_vCnpjFabricante       OUT VARCHAR2,
                               po_vFabricante           OUT VARCHAR2,
                               po_nVLBASEFCPICMS        OUT NUMBER, -- HIS.04200.2017
                               po_nVLBASEFCPST          OUT NUMBER, -- HIS.04200.2017
                               po_nVLBCFCPSTRET         OUT NUMBER, -- HIS.04200.2017
                               po_nPERFCPSTRET          OUT NUMBER, -- HIS.04200.2017
                               po_nVLFCPSTRET           OUT NUMBER, -- HIS.04200.2017
                               po_nPERFCPSN             OUT NUMBER, -- HIS.04200.2017
                               po_nVLFECP               OUT NUMBER, -- HIS.04200.2017
                               po_nVLACRESCIMOFUNCEP    OUT NUMBER, -- HIS.04200.2017
                               po_nPERACRESCIMOFUNCEP   OUT NUMBER, -- HIS.04200.2017
                               po_nALIQICMSFECP         OUT NUMBER, -- HIS.04200.2017
                               po_nVLCREDFCPICMSSN      OUT NUMBER, -- HIS.04200.2017
                               po_nCODCONFIGFUNCEPMED   OUT NUMBER,
                               pi_vOrdemCalculo          IN VARCHAR2 DEFAULT 'F',
                               pi_vMemoriaCalculo        IN VARCHAR2 DEFAULT 'N',
                               pi_nValorNotaFiscal       IN NUMBER   DEFAULT 0,
                               pi_vPedidoAvaria          IN VARCHAR  DEFAULT 'N'
                               )
  IS
  
    po_nBCSTRETANTERIOR          NUMBER;
    po_nVLICMSSUBSTITUTOANTERIOR NUMBER;
    po_nVLICMSSTRETANTERIOR      NUMBER;
    po_nSTCLIENTEGNRE            NUMBER;  
    po_nPMPF                     NUMBER;
    po_vClienteFonteSt           VARCHAR2(255);  
  
   /***************************************************************************
    ***************************************************************************
    **                  INICIO DO PROCESSAMENTO PRINCIPAL                    **
    ***************************************************************************                  
    ***************************************************************************/
  BEGIN
  
    P_OBTEM_STFONTE_42(pi_vCodFilial,
                       pi_nCodProd,
                       pi_nCodCli,
                       pi_nNumRegiao,
                       pi_nCondVenda,
                       pi_nPercVenda,
                       pio_nCodSt,
                       pi_vPVenda,
                       pi_nValorIpi,
                       pi_nPrecoMaxConsum,
                       pi_nValorUltEnt,
                       pi_nCustoNfSemSt,
                       pi_nPTabela,
                       pi_vSomenteIVATribut,
                       pi_vPesquisarCustos,
                       pi_vItemBonific,
                       pi_nVlFreteOutrasDesp,
                       po_nBaseStFonte,
                       po_nValorStFonte,
                       po_vMensagem,
                       po_vRegimeEspIsenStFonte,
                       po_nAliqIcms1,
                       po_nAliqIcms2,
                       po_nIva,
                       po_nPercBaseRedStFonte,
                       pi_vTipoChamada,
                       pi_nQT,
                       pi_nNumPedido,
                       pi_nCodFilialNf,
                       po_nPautaFonte,
                       po_vObservacaoStFonte,
                       po_vIndEscalaRelevante,
                       po_vCnpjFabricante,
                       po_vFabricante,
                       po_nVLBASEFCPICMS,
                       po_nVLBASEFCPST,
                       po_nVLBCFCPSTRET,
                       po_nPERFCPSTRET,
                       po_nVLFCPSTRET,
                       po_nPERFCPSN,
                       po_nVLFECP,
                       po_nVLACRESCIMOFUNCEP,
                       po_nPERACRESCIMOFUNCEP,
                       po_nALIQICMSFECP,
                       po_nVLCREDFCPICMSSN,
                       po_nCODCONFIGFUNCEPMED,
                       pi_vOrdemCalculo,
                       pi_vMemoriaCalculo,
                       pi_nValorNotaFiscal,
                       pi_vPedidoAvaria,
                       po_nBCSTRETANTERIOR,
                       po_nVLICMSSUBSTITUTOANTERIOR,
                       po_nVLICMSSTRETANTERIOR,
                       po_nSTCLIENTEGNRE,
                       po_nPMPF,
                       po_vClienteFonteSt);                                                             

  END P_OBTEM_STFONTE_40;
   
  /*******************************************************************************
   Nome         : P_OBTEM_STFONTE_42
   Descricão    : Procedimento Obter a Base e Valor do ST Fonte por Preço de 
                  Tabela ou Preço de Venda
                  com a Regra do ST Recolhido Anteriormente
   Parâmetros   : ENTRADA:
                  pi_vCodFilial            = Código da Filial
                  pi_nCodProd              = Código do Produto
                  pi_nCodCli               = Código do Cliente
                  pi_nNumRegiao            = Número da Região
                  pi_nCondVenda            = Tipo de Venda
                  pi_nPercVenda            = Percentual de Venda do Pedido
                  pi_vPVenda               = Preço de Venda
                  pi_nValorIpi             = Valor do Ipi                
                  pi_nPrecoMaxConsum       = Preço Max. Consumidor
                  pi_nValorUltEnt          = Valor Últ. Entrada
                  pi_nCustoNfSemSt         = Custo NF sem ST
                  pi_nPTabela              = Preço de Tabela
                  pi_vSomenteIVATribut     = 'N' em todas as chamadas exceto no 
                                                 Simples Nacional
                  pi_vPesquisarCustos      = S - Pesquisa Custos na PCEST
                                             N - Não pesquisa Custos na PCEST, 
                                                 usa os passados nos parâmetros
                  pi_vItemBonific          = S/N
                  pi_nVlFreteOutrasDesp    = Quando chamado da Package Faturamento,
                                             para ratear o Frete e Outras Despesas na
                                             Base de ST  
                  pi_vTipoChamada          = Determina o tipo de chamada da função 
                                             'F' - Chamado do Faturamento
                                             'L' - Chamado do Cálculo do ST Especial
                                                   de Operador Logísitco - HIS.01858.2015                                          
                  pi_nCodFilialNf          = Código Filial NF                           
                  ENTRADA E SAIDA:
                  pio_nCodSt               = Código da Tributação
                  SAIDA:
                  po_nBaseStFonte          = Base do ST Fonte
                  pi_nValorIpi             = Valor do ST Fonte
                  po_vMensagem             = Mensagem de Erro se ouver
                  po_vRegimeEspIsenStFonte = Se Isento de ST Fonte S/N
                  po_nPautaFonte           = Valor de Pauta ST Fonte (Farmacia Popular)
                  po_vObservacaoStFonte    = Log de Cálculo
                  po_vIndEscalaRelevante   = Escala Relevante ou Não Relevante (S/N)
                  po_vCnpjFabricante       = CNPJ Fabricante
                  po_vFabricante           = Fabricante
                  po_nVLBASEFCPICMS        =  -- HIS.04200.2017
                  po_nVLBASEFCPST          =  -- HIS.04200.2017
                  po_nVLBCFCPSTRET         =  -- HIS.04200.2017
                  po_nPERFCPSTRET          =  -- HIS.04200.2017
                  po_nVLFCPSTRET           =  -- HIS.04200.2017
                  po_nPERFCPSN             =  -- HIS.04200.2017
                  po_nVLFECP               =  -- HIS.04200.2017
                  po_nVLACRESCIMOFUNCEP    =  -- HIS.04200.2017
                  po_nPERACRESCIMOFUNCEP   =  -- HIS.04200.2017
                  po_nALIQICMSFECP         =  -- HIS.04200.2017
                  po_nVLCREDFCPICMSSN      =  -- HIS.04200.2017      
                  po_nCODCONFIGFUNCEPMED          
                  pi_vOrdemCalculo         = P - Padrão
                                           = I - Inverso
                  pi_vMemoriaCalculo       = S - Sim (Grava a Memória de Cálculo
                                             N - Não (Não grava a Memória de Cálculo)
                  pi_nValorNotaFiscal      = Valor da Nota Fiscal           
                  po_nBCSTRETANTERIOR          = Base do ST Recolhido Anteriormente
                  po_nVLICMSSUBSTITUTOANTERIOR = Base do ICMS Substituto Recolhido Anteriormente
                  po_nVLICMSSTRETANTERIOR      = Valor do ST Recolhido Anteriormente
   Alteração    : Anderson Silva - 30/09/2021 - Criação da Procedure - DDMEDICA-7697
  **********************************************************************************/                                       
  PROCEDURE P_OBTEM_STFONTE_42(pi_vCodFilial                IN VARCHAR2,
                               pi_nCodProd                  IN NUMBER,
                               pi_nCodCli                   IN NUMBER,
                               pi_nNumRegiao                IN NUMBER,
                               pi_nCondVenda                IN NUMBER,
                               pi_nPercVenda                IN NUMBER,
                               pio_nCodSt                   IN OUT NUMBER,
                               pi_vPVenda                   IN NUMBER,
                               pi_nValorIpi                 IN NUMBER,                                
                               pi_nPrecoMaxConsum           IN NUMBER,
                               pi_nValorUltEnt              IN NUMBER,
                               pi_nCustoNfSemSt             IN NUMBER,
                               pi_nPTabela                  IN NUMBER,
                               pi_vSomenteIVATribut         IN VARCHAR2,
                               pi_vPesquisarCustos          IN VARCHAR2,
                               pi_vItemBonific              IN VARCHAR2,
                               pi_nVlFreteOutrasDesp        IN NUMBER,
                               po_nBaseStFonte             OUT NUMBER,
                               po_nValorStFonte            OUT NUMBER,
                               po_vMensagem                OUT VARCHAR2,
                               po_vRegimeEspIsenStFonte    OUT VARCHAR2,
                               po_nAliqIcms1               OUT NUMBER,
                               po_nAliqIcms2               OUT NUMBER,
                               po_nIva                     OUT NUMBER,
                               po_nPercBaseRedStFonte      OUT NUMBER,
                               pi_vTipoChamada              IN VARCHAR2 DEFAULT 'O',
                               pi_nQT                       IN NUMBER DEFAULT 0,
                               pi_nNumPedido                IN NUMBER DEFAULT NULL,
                               pi_nCodFilialNf              IN VARCHAR2,
                               po_nPautaFonte              OUT NUMBER,
                               po_vObservacaoStFonte       OUT VARCHAR2,
                               po_vIndEscalaRelevante      OUT VARCHAR2,
                               po_vCnpjFabricante          OUT VARCHAR2,
                               po_vFabricante              OUT VARCHAR2,
                               po_nVLBASEFCPICMS           OUT NUMBER,
                               po_nVLBASEFCPST             OUT NUMBER,
                               po_nVLBCFCPSTRET            OUT NUMBER,
                               po_nPERFCPSTRET             OUT NUMBER,
                               po_nVLFCPSTRET              OUT NUMBER,
                               po_nPERFCPSN                OUT NUMBER,
                               po_nVLFECP                  OUT NUMBER,
                               po_nVLACRESCIMOFUNCEP       OUT NUMBER,
                               po_nPERACRESCIMOFUNCEP      OUT NUMBER,
                               po_nALIQICMSFECP            OUT NUMBER,
                               po_nVLCREDFCPICMSSN         OUT NUMBER,
                               po_nCODCONFIGFUNCEPMED      OUT NUMBER,
                               pi_vOrdemCalculo             IN VARCHAR2 DEFAULT 'F',
                               pi_vMemoriaCalculo           IN VARCHAR2 DEFAULT 'N',
                               pi_nValorNotaFiscal          IN NUMBER   DEFAULT 0,
                               pi_vPedidoAvaria             IN VARCHAR  DEFAULT 'N',
                               po_nBCSTRETANTERIOR          OUT NUMBER,
                               po_nVLICMSSUBSTITUTOANTERIOR OUT NUMBER,                               
                               po_nVLICMSSTRETANTERIOR      OUT NUMBER,
                               po_nSTCLIENTEGNRE            OUT NUMBER,
                               po_nPMPF                     OUT NUMBER,
                               po_vClienteFonteSt           OUT VARCHAR2,
                               pi_vEstEnt                   IN VARCHAR2 DEFAULT NULL, -- DDVENDAS-33718
                               pi_nQtUnitEmb                IN NUMBER DEFAULT NULL)   -- DDVENDAS-34479
                               
  IS
  
    -- Código da Filial de Faturamento - HIS.03371.2017
    vvCodFilialFaturamento       PCFILIAL.CODIGO%TYPE;
    
    -- Variáveis Auxiliares do Procedimento Principal
    v_iva                        PCTRIBUT.IVA%TYPE;
    v_ivafonte                   PCTRIBUT.IVAFONTE%TYPE;
    v_aliqicms1fonte             PCTRIBUT.ALIQICMS1FONTE%TYPE;
    v_aliqicms2fonte             PCTRIBUT.ALIQICMS2FONTE%TYPE;
    v_percbaseredstfonte         PCTRIBUT.PERCBASEREDSTFONTE%TYPE;
    v_percbaserednrpa            PCTRIBUT.PERBASEREDNRPA%TYPE;
    v_percbaseredconsumidor      PCTRIBUT.PERCBASEREDCONSUMIDOR%TYPE;
    v_utilizapercbaseredpf_trib  PCTRIBUT.UTILIZAPERCBASEREDPF%TYPE;
    v_tipocalcst                 PCCONSUM.TIPOCALCST%TYPE;
    v_calcstfontepf              PCCONSUM.CALCSTFONTEPF%TYPE;
    v_calcstpf                   PCCONSUM.CALCSTPF%TYPE;
    v_utilizapercbaseredpf_param PCCONSUM.UTILIZAPERCBASEREDPF%TYPE;
    v_clientefontest             PCCLIENT.CLIENTEFONTEST%TYPE;
    v_calculast                  PCCLIENT.CALCULAST%TYPE;
    v_ieent                      PCCLIENT.IEENT%TYPE;
    v_tipofj                     PCCLIENT.TIPOFJ%TYPE;
    v_isentoicms                 PCCLIENT.ISENTOICMS%TYPE;
    v_consumidorfinal            PCCLIENT.CONSUMIDORFINAL%TYPE;
    v_utilizaiesimplificada      PCCLIENT.UTILIZAIESIMPLIFICADA%TYPE;
    v_tipoempresa                PCCLIENT.TIPOEMPRESA%TYPE;
    v_consideraisentoscomopf     PCCONSUM.CONSIDERAISENTOSCOMOPF%TYPE;
    v_uffilial                   PCFILIAL.UF%TYPE;
    v_estent                     PCCLIENT.ESTENT%TYPE;
    v_usavalorultentbasest       PCTRIBUT.USAVALORULTENTBASEST%TYPE;
    v_valorultent                PCEST.VALORULTENT%TYPE;
    v_usaivafontediferenciado    PCCLIENT.USAIVAFONTEDIFERENCIADO%TYPE;
    v_ivafonte_cli               PCCLIENT.IVAFONTE%TYPE;
    v_AceitaPFContribuinte       PCCONSUM.ACEITAPFCONTRIBUINTE%TYPE;
    v_ALIQICMS1                  PCTRIBUT.ALIQICMS1%TYPE;
    v_ALIQICMS2                  PCTRIBUT.ALIQICMS2%TYPE;
    v_contribuinte               PCCLIENT.CONTRIBUINTE%TYPE;
    v_numcasasdecvenda           PCCONSUM.NUMCASASDECVENDA%TYPE;
    v_custonfsemst               PCEST.CUSTONFSEMST%TYPE;
    v_usavalorultentbasest2      PCTRIBUT.USAVALORULTENTBASEST2%TYPE;
    v_usapmcbasest               PCTRIBUT.USAPMCBASEST%TYPE;
    v_precomaxconsum             PCPRODUT.PRECOMAXCONSUM%TYPE;
    v_tipoclimed                 PCCLIENT.TIPOCLIMED%TYPE;
    v_isencaostorgaopub          PCTRIBUT.ISENCAOSTORGAOPUB%TYPE;
    v_usatributacaoporuf         PCCONSUM.USATRIBUTACAOPORUF%TYPE;
    v_codpraca                   PCCLIENT.CODPRACA%TYPE;
    v_numregiao                  PCREGIAO.NUMREGIAO%TYPE;
    v_usapmcuf                   PCPARAMFILIAL.VALOR%TYPE;
    v_usabaseicmsreduzida        PCTRIBUT.USABASEICMSREDUZIDA%TYPE;
    v_usabcrultent               PCTRIBUT.USABCRULTENT%TYPE;
    n_basebcrultent              PCEST.BASEBCR%TYPE;
    n_stbcrultent                PCEST.STBCR%TYPE;
    v_calcstpautafarmaciapopular PCPARAMFILIAL.VALOR%TYPE;
    n_pautafonte                 PCTRIBUT.PAUTAFONTE%TYPE;
    v_farmaciapopular            PCPRODUT.FARMACIAPOPULAR%TYPE;
    v_participafarmaciapopular   PCCLIENT.PARTICIPAFARMACIAPOPULAR%TYPE;
    v_usaptabelabasest           PCTRIBUT.USAPTABELABASEST%TYPE;
    v_simplesnacional            PCCLIENT.SIMPLESNACIONAL%TYPE; -- [HIS.05161.2014]
    n_percredpvendasimplesnac    PCTRIBUT.PERCREDPVENDASIMPLESNAC%TYPE; -- [HIS.05161.2014]
    v_tipomerc                   PCPRODUT.TIPOMERC%TYPE; -- [HIS.05161.2014]
    v_usadescsimplesnac          PCPARAMFILIAL.VALOR%TYPE; -- [HIS.05161.2014]
    v_usarajusteprecocmed        PCTRIBUT.USARAJUSTEPRECOCMED%TYPE;
    n_percajusteprecocmed        PCTRIBUT.PERCAJUSTEPRECOCMED%TYPE;
    v_usaregimeespisenstfonte    PCCLIENT.USAREGIMEESPISENSTFONTE%TYPE;
    v_regimeespisenstfonte       PCTRIBUT.REGIMEESPISENSTFONTE%TYPE;
    v_bnfnaocalculaicms          PCTRIBUT.BNFNAOCALCULAICMS%TYPE;
    v_medretirarstbnfestadual    PCPARAMFILIAL.VALOR%TYPE;
    v_medcalcularstpelopeps      PCPARAMFILIAL.VALOR%TYPE;
    v_medutilizarstfontesimplesnac  PCPARAMFILIAL.VALOR%TYPE;
    v_nqt_saldo                  PCPEDI.QT%TYPE;
    v_nqt_baixa                  PCPEDI.QT%TYPE;
    v_dtultprocessamentopeps     PCFILIAL.DTULTPROCESSAMENTOPEPS%TYPE;
    v_baseicstpeps               PCMOV.BASEICST%TYPE;
    v_stpeps                     PCMOV.ST%TYPE;
    v_percbaseredst              PCTRIBUT.PERCBASEREDST%TYPE;
    -- INICIO: HIS.03187.2015
    vUSAREGSIMPLCARGATRIBSTFONTE  PCCLIENT.USAREGSIMPLCARGATRIBSTFONTE%TYPE;
    vREGSIMPLCARGATRIBSTFONTE     PCTRIBUT.REGSIMPLCARGATRIBSTFONTE%TYPE;
    nPERCREGSIMPLCARGATRIBSTFONTE PCTRIBUT.PERCREGSIMPLCARGATRIBSTFONTE%TYPE;
    -- FIM: HIS.03187.2015
    v_precofabrica                PCPRODUT.CUSTOREP%TYPE; --// HIS.04408.2015
    vvMensagemPmc                 VARCHAR2(2000);         --// HIS.04408.2015
    -- ST Fonte Transferência
    vUSAREGRADIFSTFONTETV10       PCTRIBUT.USAREGRADIFSTFONTETV10%TYPE;
    -- 5661.146071.2016 
    vUSAREDUTORCAT49BASESTFONTE   PCTRIBUT.USAREDUTORCAT49BASESTFONTE%TYPE;
    nPERCREDUTORCAT49BASESTFONTE  PCTRIBUT.PERCREDUTORCAT49BASESTFONTE%TYPE;
    -- HIS.01277.2017
    vUSACARGAMINIMADEFERIMSTFONTE PCTRIBUT.USACARGAMINIMADEFERIMSTFONTE%TYPE; 
    nPERCARGAMINIMADEFERIMSTFONTE PCTRIBUT.PERCARGAMINIMADEFERIMSTFONTE%TYPE;
	--DDVENDAS-34782
    vUSAVLSTMAIORPERCMINPMC       PCTRIBUT.USAVLSTMAIORPERCMINPMC%TYPE; 
    nPERVLSTMAIORPERCMINPMC       PCTRIBUT.PERVLSTMAIORPERCMINPMC%TYPE;	
	
    p_pautafonteaplicado          PCTRIBUT.PAUTAFONTE%TYPE;          -- HIS.01838.2017             
    v_participafuncep             PCCLIENT.PARTICIPAFUNCEP%TYPE;     -- HIS.04200.2017
    v_utilizamotorcalculo         PCTRIBUT.UTILIZAMOTORCALCULO%TYPE; -- HIS.04200.2017
    v_formulapvenda               PCTRIBUT.FORMULAPVENDA%TYPE;       -- HIS.04200.2017               
    v_peracrescimofuncep          PCTRIBUT.PERACRESCIMOFUNCEP%TYPE;  -- HIS.04200.2017               
    v_aliqicmsfecp                PCTRIBUT.ALIQICMSFECP%TYPE;        -- HIS.04200.2017 
    v_codconfigfuncepmed          PCTRIBUT.CODCONFIGFUNCEPMED%TYPE;
    --
    vUSAREDICMNORMVENDASTFONTE    PCTRIBUT.USAREDICMNORMVENDASTFONTE%TYPE; -- MED-1080
    vPERCBASERED                  PCTRIBUT.PERCBASERED%TYPE; -- MED-1080
    -- Contador da Memória de Cálculo
    iSeqMemoriaCalculo            INTEGER;
    -- Percentual de IPI na Venda
    v_percipivenda                PCPRODUT.PERCIPIVENDA%TYPE;
    -- Novos cálculos st fonte
    v_usavlultentmediobasest      PCTRIBUT.USAVLULTENTMEDIOBASEST%TYPE;
    n_percbasestrj                PCTRIBUT.PERCBASESTRJ%TYPE;
    n_vlultentmes                 PCTABPR.VLULTENTMES%TYPE;
    -- Alíquota que receberá a Aliq 1 do ST Fonte e a Alíquota FECP para ST Inverso - MED-1930
    vnAliq1StFonteFecp            NUMBER;
    vnFecpInverso                 NUMBER;
    -- Erro Tratado
    e_tratado                     EXCEPTION;
    -- Erro Benefícios Fiscais - DDMEDICA-7584
    e_benef_fiscais               EXCEPTION;
    -- Lesgilação teto para aplicar redução de PMC
    v_usaReducaoBasePmc PCTRIBUT.USAREDUCAOBASEPMC%TYPE;
    v_pertetoredbasepmc PCTRIBUT.PERTETOREDBASEPMC%TYPE;
    -- MED-2521 - Isenção ST Bonificação
    v_isencaostfontebonificacao   PCTRIBUT.ISENCAOSTFONTEBONIFICACAO%TYPE;
    --
    v_percbaseredst_mc            PCTRIBUT.PERCBASEREDST_MC%TYPE;
    v_iva_mc                      PCTRIBUT.IVA_MC%TYPE;
    v_pauta_mc                    PCTRIBUT.PAUTA_MC%TYPE;
    v_aliqicms1_mc                PCTRIBUT.ALIQICMS1_MC%TYPE;
    v_aliqicms2_mc                PCTRIBUT.ALIQICMS2_MC%TYPE;
    vUSARABAPERDASTFONTEPEDAVARIA PCTRIBUT.USARABAPERDASTFONTEPEDAVARIA%TYPE;
    -- PMPF de Medicamentos - DDMEDICA-1691
    v_usapmpfbasest               PCTRIBUT.USAPMPFBASEST%TYPE;
    vnPmPf                        PCTABMEDABCFARMA.PMPF%TYPE;
       
    -- DDMEDICA-7594 - Valores para Customização da Base ST com SUFRAMA/Redução PISCOFINS e DESONERACAO
    v_tipocalcsulframa            PCCONSUM.TIPOCALCSULFRAMA%TYPE;
    v_agregapiscofinsst1          PCTRIBUT.AGREGAPISCOFINSST1%TYPE;
    v_agregasuframast1            PCTRIBUT.AGREGASUFRAMAST1%TYPE;
    v_agregaicmsisencaost1        PCTRIBUT.AGREGAICMSISENCAOST1%TYPE;
    v_vagregapiscofinsst2         PCTRIBUT.AGREGAPISCOFINSST2%TYPE;
    v_agregasuframast2            PCTRIBUT.AGREGASUFRAMAST2%TYPE;
    v_agregaicmsisencaost2        PCTRIBUT.AGREGAICMSISENCAOST2%TYPE;
    v_sulframa                    PCCLIENT.SULFRAMA%TYPE;
    v_orgaopub                    PCCLIENT.ORGAOPUB%TYPE;
    v_orgaopubfederal             PCCLIENT.ORGAOPUBFEDERAL%TYPE;
    v_orgaopubmunicipal           PCCLIENT.ORGAOPUBMUNICIPAL%TYPE;    
    v_perdescsuframa              PCTRIBUT.PERDESCSUFRAMA%TYPE;
    v_perdescpissuframa           PCTRIBUT.PERDESCPISSUFRAMA%TYPE;
    v_percdescpis                 PCTRIBUT.PERCDESCPIS%TYPE;
    v_percdesccofins              PCTRIBUT.PERCDESCCOFINS%TYPE;
    v_tipodescisencao             PCCLIENT.TIPODESCISENCAO%TYPE;
    v_perdescisentoicms           PCCLIENT.PERDESCISENTOICMS%TYPE;
    v_perdescicmisencao           PCTRIBUT.PERDESCICMISENCAO%TYPE;
    v_aplicadescisencaomed        PCTRIBUT.APLICADESCISENCAOMED%TYPE;
    v_destacdescicmisencaocomerc  PCTRIBUT.DESTACDESCICMISENCAOCOMERCIAL%TYPE;
    vnVlDescReducaoPis            NUMBER;
    vnPercDescReducaoPisAuxBF     NUMBER;
    vnVlDescReducaoCofins         NUMBER;
    vnPercDescReducaoCofinsAuxBF  NUMBER;
    vnVlDescIcmIsencao            NUMBER;
    vnPercDescIcmIsencaoAuxBF     NUMBER;
    vnVlDescSuframa               NUMBER;
    vnPercDescSuframaAuxBF        NUMBER;
    vnPrecoLiqResultAuxBF         NUMBER;
    vnPrecoTabResultAuxBF         NUMBER;
    vnPrecoRcaResultAuxBF         NUMBER;
    vvErrosBenefFiscais           VARCHAR2(255);
    vvMsgErrosBenefFiscais        VARCHAR2(4000);
    v_destacicmsstanterior        PCTRIBUT.DESTACICMSSTANTERIOR%TYPE;
    v_tipocalculognre             PCTRIBUT.TIPOCALCULOGNRE%TYPE;
    v_pauta_pcpautaprodutuf       PCPAUTAPRODUTUF.PAUTA%TYPE;
	v_desvincularFecpSTFuncepICMS PCTRIBUT.DESVINCULARFECPSTFUNCEPICMS%TYPE;																		
    v_utilizaCustoContBaseST      PCTRIBUT.UTILIZARCUSTOCONTBASEST%TYPE;
	vnFatorAjusteCustoCont        PCTRIBUT.FATORAJUSTECUSTOCONT%type;
	v_ncustocont          		  PCEST.CUSTOCONT%TYPE;
  
   /*************************************
    PROCEDURE: P_INSERIR_MEMORIA_CALCULO
    DESCRICAO: Inserir Memória de Cálculo
    *************************************/
    PROCEDURE P_INSERIR_MEMORIA_CALCULO(pi_vOperacao        IN VARCHAR2,
                                        pi_vDescricao       IN VARCHAR2,                                      
                                        pi_nValorAcumulado  IN NUMBER,
                                        pi_nPercentual      IN NUMBER DEFAULT NULL,
                                        pi_nValor           IN NUMBER DEFAULT NULL,
                                        pi_vGravarValorZero IN BOOLEAN DEFAULT FALSE)
    IS
    BEGIN
    
      IF (pi_vMemoriaCalculo = 'S') THEN
    
        iSeqMemoriaCalculo := NVL(iSeqMemoriaCalculo,0) + 1;
        
        -- Se Soma ou Subtração tem que ter Valor
        IF (NVL(pi_vOperacao,' ') NOT IN ('+','-')) OR
           ( (NVL(pi_vOperacao,' ') IN ('+','-')) AND (NVL(pi_nValor,0) > 0) ) OR
           ( (NVL(pi_vOperacao,' ') IN ('+','-')) AND (NVL(pi_nValor,0) = 0) AND (pi_vGravarValorZero) ) THEN    
           
          INSERT INTO PCMED_MEMORIA_CALCULO_ST     
                    ( CODPROD
                    , ORIGEM
                    , SEQ
                    , OPERACAO
                    , DESCRICAO
                    , PERCENTUAL
                    , VALOR
                    , VALORACUMULADO
                    , FLAGRESUMO )
             VALUES ( pi_nCodProd
                    , ('S'||pi_vOrdemCalculo)
                    , iSeqMemoriaCalculo
                    , pi_vOperacao
                    , pi_vDescricao
                    , pi_nPercentual
                    , pi_nValor
                    , pi_nValorAcumulado
                    , 'S' );
                    
        END IF;
  
      END IF;
      
    END P_INSERIR_MEMORIA_CALCULO;
  
   /**********************************************
    PROCEDURE: P_INSERE_OPCAO_MEMORIA_CALCULO
    DESCRICAO: Inserir Opção na Memória de Cálculo
    **********************************************/
    PROCEDURE P_INSERE_OPCAO_MEMORIA_CALCULO(pi_vDescricao     IN VARCHAR2,
                                             pi_vOpcaoCondicao IN VARCHAR2,
                                             pi_vOpcaoValor    IN VARCHAR2 DEFAULT NULL)
    IS
    BEGIN
  
      IF (pi_vMemoriaCalculo = 'S') THEN
         
        iSeqMemoriaCalculo := NVL(iSeqMemoriaCalculo,0) + 1;
        
        INSERT INTO PCMED_MEMORIA_CALCULO_ST     
                  ( CODPROD
                  , ORIGEM
                  , SEQ
                  , OPERACAO
                  , OPCAOCONDICAO
                  , OPCAOVALOR
                  , DESCRICAO
                  , FLAGRESUMO )
           VALUES ( pi_nCodProd
                  , ('S'||pi_vOrdemCalculo)
                  , iSeqMemoriaCalculo
                  , '?'
                  , pi_vOpcaoCondicao
                  , pi_vOpcaoValor
                  , pi_vDescricao
                  , 'N' );
                  
      END IF;
      
    END P_INSERE_OPCAO_MEMORIA_CALCULO;
  
   /************************************************
    PROCEDURE: P_ATU_OPCAO_MEMORIA_CALCULO
    DESCRICAO: Atualizar Opção na Memória de Cálculo
    ************************************************/
    PROCEDURE P_ATU_OPCAO_MEMORIA_CALCULO(pi_vOpcaoCondicao IN VARCHAR2,
                                          pi_vOpcaoValor    IN VARCHAR2 DEFAULT NULL)
    IS                                         
    BEGIN
    
      IF (pi_vMemoriaCalculo = 'S') THEN
  
        iSeqMemoriaCalculo := NVL(iSeqMemoriaCalculo,0) + 1;
        
        -- Limpa Opções Marcadas
        UPDATE PCMED_MEMORIA_CALCULO_ST     
           SET OPCAOSEL   = NULL
             , FLAGRESUMO = 'N'
         WHERE (CODPROD       = pi_nCodProd)
           AND (ORIGEM        = ('S'||pi_vOrdemCalculo))
           AND (OPCAOCONDICAO = pi_vOpcaoCondicao);
  
        -- Atualiza somente Opção passada no Parâmetro
        UPDATE PCMED_MEMORIA_CALCULO_ST     
           SET OPCAOSEL   = '*'
         WHERE (CODPROD       = pi_nCodProd)
           AND (ORIGEM        = ('S'||pi_vOrdemCalculo))
           AND (OPCAOCONDICAO = pi_vOpcaoCondicao) 
           AND (OPCAOVALOR    = pi_vOpcaoValor);
           
        -- Se opção marcada diferente de NAO, indica que vai mostrar Pergunta no Resumo
        IF (pi_vOpcaoValor <> 'NAO') THEN
          UPDATE PCMED_MEMORIA_CALCULO_ST     
             SET FLAGRESUMO = 'S'
           WHERE (CODPROD       = pi_nCodProd)
             AND (ORIGEM = ('S'||pi_vOrdemCalculo))
             AND (OPCAOCONDICAO = pi_vOpcaoCondicao) 
             AND (OPCAOVALOR    IS NULL); -->> Atualiza o Registro que guarda a Pergunta
          UPDATE PCMED_MEMORIA_CALCULO_ST     
             SET FLAGRESUMO = 'S'
           WHERE (CODPROD       = pi_nCodProd)
             AND (ORIGEM        = ('S'||pi_vOrdemCalculo))
             AND (OPCAOCONDICAO = pi_vOpcaoCondicao) 
             AND (OPCAOVALOR    = pi_vOpcaoValor);
        END IF;
                  
      END IF;
      
    END P_ATU_OPCAO_MEMORIA_CALCULO;
  
   /***************************
    PROCEDURE: P_OBTER_STFONTE 
    DESCRICAO: Obter o ST FONTE
    ***************************/
    PROCEDURE P_OBTER_STFONTE
      (p_codprod                    IN NUMBER,
       p_condvenda                  IN NUMBER,
       p_percvenda                  IN NUMBER,
       p_iva                        IN NUMBER,
       p_ivafonte                   IN NUMBER,
       p_aliqicms1fonte             IN NUMBER,
       p_aliqicms2fonte             IN NUMBER,
       p_percbaseredstfonte         IN NUMBER,
       p_percbaserednrpa            IN NUMBER,
       p_percbaseredconsumidor      IN NUMBER,
       p_utilizapercbaseredpf_trib  IN VARCHAR2,
       p_tipocalcst                 IN VARCHAR2,
       p_calcstpf                   IN VARCHAR2,
       p_utilizapercbaseredpf       IN VARCHAR2,
       p_clientefontest             IN VARCHAR2,
       p_calculast                  IN VARCHAR2,
       p_ieent                      IN VARCHAR2,
       p_tipofj                     IN VARCHAR2,
       p_isentoicms                 IN VARCHAR2,
       p_consumidorfinal            IN VARCHAR2,
       p_utilizaiesimplificada      IN VARCHAR2,
       p_tipoempresa                IN VARCHAR2,
       p_consideraisentoscomopf     IN VARCHAR2,
       p_pvenda                     IN NUMBER,
       p_vlipi                      IN NUMBER,
       p_uffilial                   IN VARCHAR2,
       p_estent                     IN VARCHAR2,
       p_usavalorultentbasest       IN VARCHAR2,
       p_valorultent                IN NUMBER,
       p_usaivafontediferenciado    IN VARCHAR2,
       p_ivafonte_cli               IN NUMBER,
       p_AceitaPFContribuinte       IN VARCHAR,
       p_ALIQICMS1                  IN NUMBER,
       p_ALIQICMS2                  IN NUMBER,
       p_contribuinte               IN VARCHAR2,
       p_numcasasdecvenda           IN NUMBER,
       p_custonfsemst               IN NUMBER,
       p_usavalorultentbasest2      IN VARCHAR2,
       p_usapmcbasest               IN VARCHAR2,
       p_precomaxconsum             IN NUMBER,
       p_tipoclimed                 IN VARCHAR2,
       p_isencaostorgaopub          IN VARCHAR2,
       p_usabaseicmsreduzida        IN VARCHAR2,
       p_usabcrultent               IN VARCHAR2,
       p_basebcrultent              IN NUMBER,
       p_stbcrultent                IN NUMBER,
       p_CALCSTPAUTAFARMACIAPOPULAR IN VARCHAR2,
       p_PAUTAFONTE                 IN NUMBER,
       p_FARMACIAPOPULAR            IN VARCHAR2,
       p_PARTICIPAFARMACIAPOPULAR   IN VARCHAR2, 
       p_usaptabelabasest           IN VARCHAR2,
       p_ptabela                    IN NUMBER,
       p_SomenteIVATribut           IN VARCHAR2 DEFAULT 'N',
       p_usadescsimplesnac          IN VARCHAR2 DEFAULT 'N',
       p_simplesnacional            IN VARCHAR2 DEFAULT 'N', 
       p_percredpvendasimplesnac    IN NUMBER   DEFAULT 0  ,
       p_tipomerc                   IN VARCHAR2 DEFAULT ' ',
       p_usarajusteprecocmed        IN VARCHAR2 DEFAULT 'N',
       p_percajusteprecocmed        IN NUMBER   DEFAULT 0  ,
       p_usaregimeespisenstfonte    IN VARCHAR2 DEFAULT 'N',
       p_regimeespisenstfonte       IN VARCHAR2 DEFAULT 'N',
       p_medretirarstbnfestadual    IN VARCHAR2 DEFAULT 'N',
       p_itembonific                IN VARCHAR2 DEFAULT 'N',
       p_vlfreteoutrasdesp          IN NUMBER   DEFAULT 0,
       p_bnfnaocalculaicms          IN VARCHAR2 DEFAULT 'N',
       p_USAREGSIMPLCARGATRIBSTFONTE  IN VARCHAR2 DEFAULT 'N', -- HIS.03187.2015
       p_REGSIMPLCARGATRIBSTFONTE     IN VARCHAR2 DEFAULT 'N', -- HIS.03187.2015
       p_PERCREGSIMPLCARGATRIBSTFONTE IN NUMBER   DEFAULT 0,   -- HIS.03187.2015     
       p_USAREDUTORCAT49BASESTFONTE   IN VARCHAR2 DEFAULT 'N', -- 5661.146071.2016
       p_PERCREDUTORCAT49BASESTFONTE  IN NUMBER   DEFAULT 0,   -- 5661.146071.2016                  
       p_USACARGAMINIMADEFERIMSTFONTE IN VARCHAR2 DEFAULT 'N', -- HIS.01277.2017
       p_PERCARGAMINIMADEFERIMSTFONTE IN NUMBER   DEFAULT 0,   -- HIS.01277.2017   
       p_USAVLSTMAIORPERCMINPMC       IN VARCHAR2 DEFAULT 'N', -- DDVENDAS-34782
       p_PERVLSTMAIORPERCMINPMC       IN NUMBER   DEFAULT 0,   -- DDVENDAS-34782
       po_nBaseStFonte               OUT NUMBER,
       po_nValorStFonte              OUT NUMBER,
       po_vMensagem                  OUT VARCHAR2,
       po_vRegimeEspIsenStFonte      OUT VARCHAR2,
       po_nAliqIcms1                 OUT NUMBER,
       po_nAliqIcms2                 OUT NUMBER,
       po_nIva                       OUT NUMBER,
       po_nPercBaseRedStFonte        OUT NUMBER,
       po_nPautaFonte                OUT NUMBER,   -- HIS.01838.2017             
       po_vObservacaoStFonte         OUT VARCHAR2, -- HIS.01838.2017             
       p_codfilialfaturamento        IN VARCHAR2,  -- HIS.03371.2017
       p_indescalarelevante          IN VARCHAR2,  -- HIS.03371.2017
       p_participafuncep             IN VARCHAR2,  -- HIS.04200.2017
       p_utilizamotorcalculo         IN VARCHAR2,  -- HIS.04200.2017
       p_formulapvenda               IN VARCHAR2,  -- HIS.04200.2017             
       p_peracrescimofuncep          IN NUMBER,    -- HIS.04200.2017               
       p_aliqicmsfecp                IN NUMBER,    -- HIS.04200.2017
       p_codconfigfuncepmed          IN NUMBER,     
       p_vlbasefcpicms               OUT NUMBER,   -- HIS.04200.2017
       p_vlbasefcpst                 OUT NUMBER,   -- HIS.04200.2017
       p_vlbcfcpstret                OUT NUMBER,   -- HIS.04200.2017
       p_perfcpstret                 OUT NUMBER,   -- HIS.04200.2017
       p_vlfcpstret                  OUT NUMBER,   -- HIS.04200.2017
       p_perfcpsn                    OUT NUMBER,   -- HIS.04200.2017
       p_vlfecp                      OUT NUMBER,   -- HIS.04200.2017
       p_vlacrescimofuncep           OUT NUMBER,   -- HIS.04200.2017
       p_vlcredfcpicmssn             OUT NUMBER,   -- HIS.04200.2017                                            
       po_nPerAcrescimoFuncep        OUT NUMBER,   -- HIS.04200.2017                                            
       po_nAliqIcmsFecp              OUT NUMBER,   -- HIS.04200.2017                                            
       po_nCodConfigFuncepMed        OUT NUMBER,
       p_USAREDICMNORMVENDASTFONTE   IN VARCHAR2,  -- MED-1080
       p_PERCBASERED                 IN NUMBER,    -- MED-1080
       p_percipivenda                IN NUMBER,
       p_usavlultentmediobasest      IN VARCHAR2, 
       p_percbasestrj                IN NUMBER,
       p_vlultentmes                 IN NUMBER,
       p_valornotafiscal             IN NUMBER,
       p_usaReducaoBasePmc           IN VARCHAR2 DEFAULT 'N', -- MED-2428
       p_pertetoredbasepmc           IN NUMBER   DEFAULT 0,   -- MED-2428
       p_isencaostfontebonificacao   IN VARCHAR2, -- MED-2521
       p_usapmpfbasest               IN VARCHAR2,
       p_pmpf                        IN NUMBER,
       -- DDMEDICA-7594
       p_agregapiscofinsst1          IN VARCHAR2,
       p_agregasuframast1            IN VARCHAR2,
       p_agregaicmsisencaost1        IN VARCHAR2,
       p_agregapiscofinsst2          IN VARCHAR2,
       p_agregasuframast2            IN VARCHAR2,
       p_agregaicmsisencaost2        IN VARCHAR2,
       p_vldescreducaopis            IN NUMBER,
       p_vldescreducaocofins         IN NUMBER,
       p_vldescicmisencao            IN NUMBER,
       p_vldescsuframa               IN NUMBER,
       v_destacicmsstanterior        IN VARCHAR2,
       po_nBcStRetAnterior          OUT NUMBER,
       po_nVlIcmsSubstitutoAnterior OUT NUMBER,
       po_nVlIcmsStRetAnterior      OUT NUMBER,
       p_tipocalculognre             IN VARCHAR2,
       po_nStClienteGnre            OUT NUMBER,
       po_nPmPf                     OUT NUMBER,
       p_desvincularFecpSTFuncepICMS IN VARCHAR2,
	   p_utilizaCustoContBaseST      IN VARCHAR2,
       p_nFatorAjusteCustoCont       IN NUMBER,
       p_ncustocont                  IN NUMBER)  
    IS
    
      -- Preço de Venda sem Impostos
      vnPrecoVendaSemImpostos        NUMBER;
  
      -- Variaveis Auxiliares
      n_ivafonte                     NUMBER;
      n_aliqicms1fonte               NUMBER;
      n_aliqicms2fonte               NUMBER;
      n_percbaseredstfonte           NUMBER;
      --
      vvusabaseicmsreduzida          pctribut.usabaseicmsreduzida%type;
      -- 5661.146071.2016
      vnPercBaseRedStFonteAlterado   NUMBER;
      
      vnRetVlFreteOutrasDespBaseSt   NUMBER; -- MED-2346
      vnRetPercBaseRedIcmsFecp       NUMBER; -- MED-2346
      
      -- Valores para gravação do ST recolhido anteriormente
      vvRetEnquadraIcmsSubstAnterior VARCHAR2(1);
      vnRetVlIcmsSubstitutoAnterior  NUMBER;
      
      -------------------------------------------------------------------------------------------------------------------
      -------------------------------------------------------------------------------------------------------------------
      -------------------------------------------------------------------------------------------------------------------
      -- FUNCTION FCALCULARSTFONTE
      --42 parametros ( mas pode ser usada pode packages que utilizam a de 38 parÂmetros)
      -------------------------------------------------------------------------------------------------------------------
      -------------------------------------------------------------------------------------------------------------------
      -------------------------------------------------------------------------------------------------------------------
      FUNCTION FCALCULARSTFONTE(p_codprod                    IN NUMBER,
                                p_condvenda                  IN NUMBER,
                                p_percvenda                  IN NUMBER,
                                p_iva                        IN NUMBER,
                                p_ivafonte                   IN OUT NUMBER,
                                p_aliqicms1fonte             IN OUT NUMBER,
                                p_aliqicms2fonte             IN OUT NUMBER,
                                p_percbaseredstfonte         IN OUT NUMBER,
                                p_percbaserednrpa            IN NUMBER,
                                p_percbaseredconsumidor      IN NUMBER,
                                p_utilizapercbaseredpf_trib  IN VARCHAR2,
                                p_tipocalcst                 IN VARCHAR2,
                                p_calcstpf                   IN VARCHAR2,
                                p_utilizapercbaseredpf       IN VARCHAR2,
                                p_clientefontest             IN VARCHAR2,
                                p_calculast                  IN VARCHAR2,
                                p_ieent                      IN VARCHAR2,
                                p_tipofj                     IN VARCHAR2,
                                p_isentoicms                 IN VARCHAR2,
                                p_consumidorfinal            IN VARCHAR2,
                                p_utilizaiesimplificada      IN VARCHAR2,
                                p_tipoempresa                IN VARCHAR2,
                                p_consideraisentoscomopf     IN VARCHAR2,
                                p_pvenda                     IN NUMBER,
                                p_vlipi                      IN NUMBER,
                                p_uffilial                   IN VARCHAR2,
                                p_estent                     IN VARCHAR2,
                                p_usavalorultentbasest       IN VARCHAR2,
                                p_valorultent                IN NUMBER,
                                p_usaivafontediferenciado    IN VARCHAR2,
                                p_ivafonte_cli               IN NUMBER,
                                p_AceitaPFContribuinte       IN VARCHAR,
                                p_ALIQICMS1                  IN NUMBER,
                                p_ALIQICMS2                  IN NUMBER,
                                p_contribuinte               IN VARCHAR2,
                                p_numcasasdecvenda           in NUMBER,
                                p_baseicst                   IN OUT NUMBER,
                                p_PercBaseRedStFonteAlterado OUT NUMBER, -->> SE A LEGISLAÇÃO MUDAR O % DE REDUÇÃO DO CADASTRO - 5661.146071.2016
                                p_mensagem                   OUT VARCHAR2,
                                P_CUSTONFSEMST               in pcest.custonfsemst%type default 0,
                                p_usavalorultentbasest2      in pctribut.usavalorultentbasest2%type default 'N',
                                p_usapmcbasest               in pctribut.usapmcbasest%type default 'N' ,
                                p_precomaxconsum             in pcprodut.precomaxconsum%type default 0 ,
                                p_usabaseicmsreduzida        in pctribut.usabaseicmsreduzida%type default 'N',
                                p_usabcrultent               IN VARCHAR2,
                                p_basebcrultent              IN NUMBER,
                                p_stbcrultent                IN NUMBER,
                                p_CALCSTPAUTAFARMACIAPOPULAR IN VARCHAR2,
                                p_PAUTAFONTE                 IN NUMBER,
                                p_FARMACIAPOPULAR            IN VARCHAR2,
                                p_PARTICIPAFARMACIAPOPULAR   IN VARCHAR2,   
                                p_usaptabelabasest           IN VARCHAR2,
                                p_ptabela                    IN NUMBER,
                                p_somenteIVATribut           IN VARCHAR2,
                                p_usadescsimplesnac          IN VARCHAR2,
                                p_simplesnacional            IN VARCHAR2,
                                p_percredpvendasimplesnac    IN NUMBER,
                                p_tipomerc                   IN VARCHAR2,
                                p_usarajusteprecocmed        IN VARCHAR2,
                                p_percajusteprecocmed        IN NUMBER,
                                p_medretirarstbnfestadual    IN VARCHAR2,
                                p_itembonific                IN VARCHAR2,
                                p_vlfreteoutrasdesp          IN NUMBER,
                                p_bnfnaocalculaicms          IN VARCHAR2,
                                p_USAREGSIMPLCARGATRIBSTFONTE  IN VARCHAR2 DEFAULT 'N',
                                p_REGSIMPLCARGATRIBSTFONTE     IN VARCHAR2 DEFAULT 'N',
                                p_PERCREGSIMPLCARGATRIBSTFONTE IN NUMBER   DEFAULT 0,
                                p_USAREDUTORCAT49BASESTFONTE   IN VARCHAR2 DEFAULT 'N',
                                p_PERCREDUTORCAT49BASESTFONTE  IN NUMBER   DEFAULT 0,
                                p_USACARGAMINIMADEFERIMSTFONTE IN VARCHAR2 DEFAULT 'N',
                                p_PERCARGAMINIMADEFERIMSTFONTE IN NUMBER   DEFAULT 0,								
                                p_USAVLSTMAIORPERCMINPMC       IN VARCHAR2 DEFAULT 'N',
                                p_PERVLSTMAIORPERCMINPMC       IN NUMBER   DEFAULT 0,																
                                p_pautafonteaplicado           OUT NUMBER,
                                p_observacaostfonte            OUT VARCHAR2,
                                p_codfilialfaturamento         IN VARCHAR2,
                                p_USAREDICMNORMVENDASTFONTE    IN VARCHAR2,
                                p_PERCBASERED                  IN NUMBER,
                                p_percipivenda                 IN NUMBER,
                                p_usavlultentmediobasest       IN VARCHAR2, 
                                p_percbasestrj                 IN NUMBER,
                                p_vlultentmes                  IN NUMBER,
                                po_nVlFreteOutrasDespBaseIcms  OUT NUMBER,
                                po_nPercBaseRedIcmsFecp        OUT NUMBER,
                                p_usaReducaoBasePmc            IN VARCHAR2 DEFAULT 'N',
                                p_pertetoredbasepmc            IN NUMBER   DEFAULT 0,
                                p_usapmpfbasest                in pctribut.usapmpfbasest%type,
                                p_pmpf                         IN NUMBER,
                                p_agregapiscofinsst1           IN VARCHAR2,
                                p_agregasuframast1             IN VARCHAR2,
                                p_agregaicmsisencaost1         IN VARCHAR2,
                                p_vagregapiscofinsst2          IN VARCHAR2,
                                p_agregasuframast2             IN VARCHAR2,
                                p_agregaicmsisencaost2         IN VARCHAR2,
                                p_vldescreducaopis             IN NUMBER,
                                p_vldescreducaocofins          IN NUMBER,
                                p_vldescicmisencao             IN NUMBER,
                                p_vldescsuframa                IN NUMBER,
                                po_vEnquadraIcmsSubstAnterior OUT VARCHAR2,
                                po_nVlIcmsSubstitutoAnterior  OUT NUMBER,
                                po_nPmPf                      OUT NUMBER,
								p_utilizaCustoContBaseST      in VARCHAR2,
								p_FatorAjusteCustoCon         in NUMBER,
								p_ncustocont				  in NUMBER)
      RETURN NUMBER IS
      
        -- Variáveis Locais da Função
        vnpercbasered                  NUMBER;
        vnpercbaseredBaseCred          NUMBER;
        vnpercbaseredIcmsFecp          NUMBER;
        vnbcst                         NUMBER;
        vnstf1                         NUMBER;
        vnstf2                         NUMBER;
        vnstfonte                      NUMBER;
        vnpbase                        NUMBER;
        vbPessoaFisica                 BOOLEAN;
        vscontribuinte                 PCCLIENT.CONTRIBUINTE%TYPE;
        vnIvaFonte                     NUMBER;
        vbCalculaSTFonte               BOOLEAN;
        vnpvenda                       NUMBER;
        vncustonfsemst                 PCEST.CUSTONFSEMST%TYPE;
        -- Regra Farmácia Popular
        vbRegraFciaPopular             BOOLEAN;
        -- Regra Usar PMC na Base do ST
        vbUsaPmcBaseSt                 BOOLEAN;
        -- PMC de Referência para Ajuste Preço CMED
        vnPmcAjustePrecoCMED           NUMBER;
        -- Valor do Frete e Despesas Acessórias a Somar nas Base de ST
        vnVlFreteOutrasDespBaseSt      NUMBER;
        -- Valor do Frete e Despesas Acessórias a Somar nas Base de ICMS
        vnVlFreteOutrasDespBaseIcms    NUMBER;
        -- Se usa Regra Regime Simplificado pela Carga Tributária Média                   
        vbUsaRegraRegSimplCargaTrib    BOOLEAN;
        vnBcIcmsOperPropriaCargaTribut NUMBER;
        vnVlIcmsOperPropriaCargaTribut NUMBER;
        vnBcEstimatSimplifCargaTribut  NUMBER;
        vnVlEstimatSimplifCargaTribut  NUMBER;
        -- Se usa ST da Última Entrada
        vbUsaRegraStUltimaEntrada      BOOLEAN;
        -- Se Ignorar ST Fonte no TV 10 quando valores zerados na tributação
        vvIgnorarSTFonteTV10Zerado     VARCHAR2(1);  
        -- Regra Exceção ST Fonte Paraná
        vvUsaRegraSTParanaOutrasDesp   VARCHAR2(1);
        -- Base ST Original sem Redução - 5661.146071.2016
        vnBaseStOriginalSemReducao     NUMBER;
        -- HIS.01277.2017
        vnStFonteCargaMinima           NUMBER;
        vnStPercMinPMC                 NUMBER;
        -- Variáveis Auxiliares da Memória de Calculo
        vnPercMemoriaCalculo           NUMBER;
        vnValorCalculadoMemoriaCalculo NUMBER;
        vvDescOpcaoSelMemoriaCalculo   VARCHAR2(200);
        -- Variáveis para cálculo do ST RJ
        vnBaseStRj                     NUMBER;
        vnValorStRj                    NUMBER;
        vnPercBaseRedRj                NUMBER;
        -- Regra Usar PMPF na Base do ST
        vbUsaPmPfBaseSt                BOOLEAN;
        -- DDMEDICA-7594 - Valores para Customização da Base ST com SUFRAMA/Redução PISCOFINS e DESONERACAO
        -- B1 = Base da Alíquota 1,  B2 = Base da Alíquota 2
        vnVlDescReducaoPisCofins_B1    NUMBER;
        vnVlDescSuframaPisSuframa_B1   NUMBER;
        vnVlDescIcmIsencao_B1          NUMBER;
        vbUsouIVAFonte_B1              BOOLEAN;
        vnVlDescReducaoPisCofins_B2    NUMBER;
        vnVlDescSuframaPisSuframa_B2   NUMBER;
        vnVlDescIcmIsencao_B2          NUMBER;
        vnBaseSTPB             		   NUMBER;
		vnStFonteCustoCont             NUMBER;									  
      BEGIN
         
       /********************
        Inicializa Variáveis
        ********************/
      
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte         := 'St.Fonte';
      
        -- Regra Farmácia Popular
        vbRegraFciaPopular          := ( (NVL(p_CALCSTPAUTAFARMACIAPOPULAR,'N') = 'S') and
                                         (NVL(p_FARMACIAPOPULAR,'N') = 'S') and
                                         (NVL(p_PARTICIPAFARMACIAPOPULAR,'N') = 'S') and
                                         (NVL(p_PAUTAFONTE,0) > 0) );
       
        -- Regra Usar PMC na Base do ST
        vbUsaPmcBaseSt              := ( (NVL(p_PRECOMAXCONSUM,0) > 0) and
                                         (NVL(p_USAPMCBASEST,'N') = 'S') );
  
        -- Rgra Usa ST da Última Entrada (Se não for Consumidor Final)
        vbUsaRegraStUltimaEntrada   := ( (NVL(p_usabcrultent,'N')     = 'S') AND
                                         (NVL(p_consumidorfinal,'N') <> 'S') ); 
  
        -- Regra Regime Simplificado pela Carga Tributária Média -- HIS.03187.2015                                    
        vbUsaRegraRegSimplCargaTrib := ( (NVL(p_USAREGSIMPLCARGATRIBSTFONTE,'N') = 'S') and
                                         (NVL(p_REGSIMPLCARGATRIBSTFONTE,'N')    = 'S') and
                                         (NVL(p_PERCREGSIMPLCARGATRIBSTFONTE,0)  > 0) );
                              
        -- Regra Usar PMPF na Base do ST
        vbUsaPmPfBaseSt             := ( (NVL(p_PMPF,0) > 0) and
                                         (NVL(p_USAPMPFBASEST,'N') = 'S') );
                              
        -- Regra Exceção ST Fonte Paraná para Somar Outras Despesas na Base ICMS com PMC na Base do ST                                      
        BEGIN
          SELECT VALOR
            INTO vvUsaRegraSTParanaOutrasDesp
            FROM PCREGRASEXCECAOMED
           WHERE (CODFILIAL = '99')
             AND (NOME      = 'USAREGRASTPARANAOUTRASDESP');
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vvUsaRegraSTParanaOutrasDesp := 'N';
        END;                     
  
       /***************************
        Inicializa Outras Variáveis
        ***************************/
  
        -- Retorno - SE A LEGISLAÇÃO MUDAR O % DE REDUÇÃO DO CADASTRO - 5661.146071.2016      
        p_PercBaseRedStFonteAlterado := NULL; 
  
        -- MED-2346 - Valores para FECP
        po_nVlFreteOutrasDespBaseIcms := NULL; 
        po_nPercBaseRedIcmsFecp       := NULL; 
        
        -- Outras Variáveis
        vnbcst                        := 0;
        vnstf1                        := 0;
        vnstf2                        := 0;
        vnstfonte                     := 0;
        vbPessoaFisica                := False;
        vnIvaFonte                    := p_IVAFONTE;
        vbCalculaSTFonte              := True;
        --
        vscontribuinte                := p_contribuinte;
        --
        vnpvenda                      := p_pvenda;
        --
        vnVlFreteOutrasDespBaseSt     := 0;
        vnVlFreteOutrasDespBaseIcms   := 0;           
        -- DDMEDICA-7594 - Valores para Customização da Base ST com SUFRAMA/Redução PISCOFINS e DESONERACAO
        vnVlDescReducaoPisCofins_B1   := 0;
        vnVlDescSuframaPisSuframa_B1  := 0;
        vnVlDescIcmIsencao_B1         := 0;
        vbUsouIVAFonte_B1             := FALSE;                 
        vnVlDescReducaoPisCofins_B2   := 0;
        vnVlDescSuframaPisSuframa_B2  := 0;
        vnVlDescIcmIsencao_B2         := 0;
        -- Valores para gravação do ST recolhido anteriormente
        po_vEnquadraIcmsSubstAnterior := 'N';
        po_nVlIcmsSubstitutoAnterior  := 0;

        -- Custo NF sem ST
        vncustonfsemst   := p_custonfsemst;   
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
      
       /**********************
        Define se Usa ST Fonte
        **********************/
      
        -- Identificar a incidência de ST Fonte [RDB05]
        vbCalculaSTFonte := (p_CLIENTEFONTEST = 'S')  and
                            ((p_ALIQICMS1FONTE > 0) or (p_ALIQICMS2FONTE > 0));-- and  ((p_ALIQICMS1 = 0) or (p_ALIQICMS2 = 0));
      
        vbCalculaSTFonte := vbCalculaSTFonte and
                            (not ((p_CALCSTPF = 'N') and (vbpessoafisica)));
        
        -- Item Bonificado com Regime Especial pra Retirar ST da Bonificação da NF Estadual
        IF ((NVL(p_itembonific,'N') = 'S') AND
            (NVL(p_medretirarstbnfestadual,'N') = 'S') AND
            (p_uffilial = p_estent)) THEN
          vbCalculaSTFonte            := FALSE;
          vbUsaRegraRegSimplCargaTrib := FALSE; -- HIS.03187.2015
        END IF;
        
        -- Se for Pedido TV10
        IF (pi_nCondVenda = 10) THEN
      
          -- Verifica exceção para ignorar ST Fonte TV 10 quando valores zerados na tibutação
          BEGIN
            SELECT NVL(VALOR,'N')
              INTO vvIgnorarSTFonteTV10Zerado
              FROM PCREGRASEXCECAOMED
             WHERE NOME      = 'IGNORARSTFONTETV10ZERADO'
               AND CODFILIAL = '99';  
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vvIgnorarSTFonteTV10Zerado := 'N';
          END;     
        
          -- Se possuir a regra
          IF vvIgnorarSTFonteTV10Zerado = 'S' THEN
            -- Reinicializa a variável
            vvIgnorarSTFonteTV10Zerado := 'N';
            -- Verifica se os campos estão zerados 
            BEGIN
              SELECT 'S'
                INTO vvIgnorarSTFonteTV10Zerado
                FROM PCTRIBUT 
               WHERE CODST = pio_nCodSt
                 AND NVL(IVATRANSF,0)              <= 0
                 AND NVL(ALIQICMS1TRANSF,0)        <= 0
                 AND NVL(ALIQICMS2TRANSF,0)        <= 0
            	   AND NVL(PAUTATRANSF,0)            <= 0
                 AND NVL(PERCBASEREDSTTRANSF,0)    <= 0
                 AND NVL(IVAFONTETV10,0)           <= 0
                 AND NVL(ALIQICMS1FONTETV10,0)     <= 0
            	   AND NVL(ALIQICMS2FONTETV10,0)     <= 0
                 AND NVL(PERCBASEREDSTFONTETV10,0) <= 0
                 AND NVL(PAUTAFONTETV10,0)         <= 0;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                vvIgnorarSTFonteTV10Zerado := 'N';
            END; 
            
            -- Se os valores para os campos estão zerados, não calcula ST Fonte
            IF (vvIgnorarSTFonteTV10Zerado = 'S') THEN
              vbCalculaSTFonte := FALSE;
            END IF; 
                     
          END IF; -- Fim-Se possui regra para ignorar ST com valores zerados
        END IF; -- Fim-Se Pedido TV10     
        
       /*********************************************************************************************
        *********************************************************************************************
        **                     CALCULAR VALOR DO ST PELA ULTIMA ENTRADA                            **
        *********************************************************************************************
        *********************************************************************************************/
        IF   (vbUsaRegraStUltimaEntrada) AND
             (vbCalculaSTFonte)          THEN -->> HIS.03788.2015 - Somente se for STFONTE
  
          -------------------------------------------
          -- Se usa o PEPS e é Chamado do Faturamento
          -------------------------------------------
          IF (pi_vTipoChamada = 'F') AND
             (v_medcalcularstpelopeps = 'S') THEN
          
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',PEPS';
          
             -- Total de itens (Saldo). 
             v_nqt_saldo := NVL(pi_nQT,0);
             -- Apagando a movimentação da temporária
             DELETE FROM PCPEPSSALDOTEMP;
             
             -- Cursor para identificar as transações.
             FOR CR_PEPS IN (SELECT M.NUMTRANSPEPS
                                  , E.DTENT
                                  , SUM(SALDO) SALDO
                                FROM   (   -- Saldo PEPS até último fechamento
                                        SELECT   S.NUMTRANSENT NUMTRANSPEPS, SUM (S.QTSALDO) SALDO
                                          FROM   PCPEPSSALDO S
                                         WHERE   S.CODFILIAL = p_codfilialfaturamento -- HIS.03371.2017
                                           AND   S.CODPROD = pi_nCodProd
                                        GROUP BY S.NUMTRANSENT
                                    UNION  -- Entradas após último fechamento
                                        SELECT   N.NUMTRANSENT NUMTRANSPEPS, SUM (M.QTCONT) SALDO
                                          FROM   PCNFENT N, PCMOV M
                                         WHERE   NVL (N.CODFILIALNF, N.CODFILIAL) = p_codfilialfaturamento -- HIS.03371.2017
                                               AND N.DTENT >= V_dtultprocessamentopeps+1
                                               AND N.ESPECIE = 'NF'
                                               AND M.NUMTRANSENT = N.NUMTRANSENT
                                               AND M.CODPROD = pi_nCodProd
                                               AND M.QTCONT > 0
                                               AND M.STATUS IN ('A', 'AB')
                                               AND N.TIPODESCARGA <> 'F'
                                               AND NVL (N.NFENTREGAFUTURA, 'N') = 'N'
                                               AND M.CODOPER IN ('E', 'EB', 'ET', 'ED', 'ER', 'EI')
                                               AND M.DTCANCEL IS NULL
                                               AND NOT EXISTS
                                                     (SELECT   CODPROD
                                                        FROM   PCMOVENT
                                                       WHERE       NUMTRANSENT = N.NUMTRANSENT
                                                               AND CODFILIAL = p_codfilialfaturamento -- HIS.03371.2017
                                                               AND CODPROD = M.CODPROD)
                                          GROUP BY N.NUMTRANSENT
                                    UNION  -- Saídas após último fechamento
                                        SELECT   C.NUMTRANSPEPS, SUM (M.QTCONT) * (-1) SALDO
                                          FROM   PCNFSAID N, PCMOV M, PCMOVCOMPLE C
                                         WHERE   NVL (M.CODFILIALNF, M.CODFILIAL) = p_codfilialfaturamento -- HIS.03371.2017
                                               AND M.DTMOV >= V_dtultprocessamentopeps+1
                                               AND M.NUMTRANSVENDA = N.NUMTRANSVENDA
                                               AND M.CODPROD = pi_nCodProd
                                               AND N.ESPECIE = 'NF'
                                               AND M.QTCONT > 0
                                               AND M.STATUS IN ('A', 'AB')
                                               AND M.CODOPER IN ('S', 'SB', 'ST', 'SD', 'SP', 'SR', 'SI')
                                               AND NVL (M.CODFISCAL, 0) NOT IN (5929, 6929)
                                               AND NVL (N.CONDVENDA, 0) NOT IN (3, 6, 7, 12, 13)
                                               AND NVL (N.FINALIDADENFE, 'O') <> 'C'
                                               AND M.DTCANCEL IS NULL
                                               AND N.DTCANCEL IS NULL
                                               AND C.NUMTRANSITEM = M.NUMTRANSITEM
                                          GROUP BY C.NUMTRANSPEPS
                                    UNION  -- Saldo já reservado no Pedido (outros lotes)
                                        SELECT   I.NUMTRANSPEPS, SUM (I.QT) * (-1) SALDO
                                          FROM   PCPEDC P, PCPEDI I
                                         WHERE   NVL (P.CODFILIALNF, P.CODFILIAL) = p_codfilialfaturamento -- HIS.03371.2017
                                               AND P.NUMPED = pi_nNumPedido
                                               AND I.CODPROD = pi_nCodProd
                                               AND NVL (P.CONDVENDA, 0) NOT IN (3, 6, 7, 12, 13)
                                               AND NVL (I.NUMTRANSPEPS,0) > 0
                                               AND P.NUMPED = I.NUMPED
                                         GROUP BY I.NUMTRANSPEPS
                                          ) M, PCNFENT E
                         WHERE M.NUMTRANSPEPS = E.NUMTRANSENT(+)
                         GROUP BY M.NUMTRANSPEPS, E.DTENT
                        HAVING SUM(SALDO) > 0 -->> SOMENTE COM SALDO
                         ORDER BY E.DTENT, M.NUMTRANSPEPS)
             LOOP
             
              -- CALCULANDO A QUANTIDADE DE BAIXA POR TRANSAÇÃO.
               v_nqt_baixa := 0; 
               IF (NVL(CR_PEPS.SALDO,0) >= NVL(v_nqt_saldo,0)) then
                 -- Se tem Saldo no PEPS para atender totalmente a quantidade
                 v_nqt_baixa := NVL(v_nqt_saldo,0);
                 v_nqt_saldo := 0;
               else
                 -- Se NÃO tem Saldo no PEPS para atender toda a quantidade
                 v_nqt_baixa := NVL(CR_PEPS.SALDO,0);
                 v_nqt_saldo := NVL(v_nqt_saldo,0) - NVL(v_nqt_baixa,0);  
               end if;
               
               -- BUSCANDO INFORMAÇÃO DE BASE ST E ST DA TRANSAÇÃO DE ENTRADA.
               BEGIN
                   SELECT BASEBCR
                        , STBCR
                     INTO v_baseicstpeps
                        , v_stpeps                   
                     FROM PCMOV
                    WHERE NUMTRANSENT = CR_PEPS.NUMTRANSPEPS
                      AND CODPROD = pi_nCodProd
                      AND ROWNUM = 1; 
                         
                   -- Por enquanto respeitam a tributação as variáveis abaixo
                   V_iva                := p_iva;
                   V_ivafonte           := p_ivafonte;
                   V_aliqicms1fonte     := p_aliqicms1fonte;
                   V_aliqicms2fonte     := p_aliqicms2fonte;
                   V_percbaseredstfonte := p_percbaseredstfonte;
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    po_vMensagem := 'Não foi encontrado movimento para a transação ' + CR_PEPS.NUMTRANSPEPS + ' no processo do PEPS';
                    RAISE e_tratado;
                END;                  
               
               -- INSERINDO NA TEMPORÁRIA
               INSERT INTO PCPEPSSALDOTEMP (NUMTRANSPEPS
                                           ,CODPROD
                                           ,QTSALDO
                                           ,BASEICST
                                           ,ST
                                           ,IVA
                                           ,IVAFONTE
                                           ,ALIQICMS1FONTE 
                                           ,ALIQICMS2FONTE
                                           ,PERCBASEREDSTFONTE)
                                     VALUES
                                           (CR_PEPS.NUMTRANSPEPS
                                           ,pi_nCodProd
                                           ,v_nqt_baixa
                                           ,v_baseicstpeps
                                           ,v_stpeps
                                           ,V_iva
                                           ,V_ivafonte
                                           ,V_aliqicms1fonte 
                                           ,V_aliqicms2fonte
                                           ,V_percbaseredstfonte);
  
               -- Reservou toda a Quantidade do Item do Pedido no PEPS
               IF (NVL(v_nqt_saldo,0) <= 0) THEN
                  EXIT;
               END IF;
               
             END LOOP;                              
             
             -- Se ainda ficar saldo grava com os dados da PCEST
             IF (NVL(v_nqt_saldo,0) > 0) THEN
               -- INSERINDO NA TEMPORÁRIA
               INSERT INTO PCPEPSSALDOTEMP (NUMTRANSPEPS
                                           ,CODPROD
                                           ,QTSALDO
                                           ,BASEICST
                                           ,ST
                                           ,IVA
                                           ,IVAFONTE
                                           ,ALIQICMS1FONTE 
                                           ,ALIQICMS2FONTE
                                           ,PERCBASEREDSTFONTE)
                                     VALUES
                                           (NULL        -->> Não terá NUMTRANSPEPS
                                           ,pi_nCodProd
                                           ,v_nqt_saldo -->> Saldo Restante do Item do Pedido
                                           ,NVL(p_basebcrultent,0)
                                           ,NVL(p_stbcrultent,0)
                                           ,p_iva
                                           ,p_ivafonte
                                           ,p_aliqicms1fonte 
                                           ,p_aliqicms2fonte
                                           ,p_percbaseredstfonte);
               v_nqt_saldo := 0;                                          
             END IF;
             
          ----------------------------------------------------------------------
          -- Se não usa o PEPS ou se usa o PEPS mas não é chamado do Faturamento
          ----------------------------------------------------------------------
          ELSE 
            -- Usa Valores da PCEST
            vnbcst    := NVL(p_basebcrultent,0);
            vnstfonte := NVL(p_stbcrultent,0);
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',PEPS PcEst';
          END IF;
           
       /*********************************************************************************************
        *********************************************************************************************
        **            CALCULAR VALOR DO ST PELA CARGA TRIBUTÁRIA MÉDIA - HIS.03187.2015            **
        *********************************************************************************************
        *********************************************************************************************/
        ELSIF (vbUsaRegraRegSimplCargaTrib) AND
              (vbCalculaSTFonte)            THEN -->> HIS.03371.2017 - Somente se for STFONTE
            
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',Carga Trib.Média';
            
        /*   
         Base ST = [Valor Operação Própria] + [Valor Estimativa Simplificada Carga Tributária Média]
                   ---------------------------------------------------------------------------------
                     		                        Percentual ICMS Interno
  
         Base ST = [Valor Produtos x (Aliq2/100)] + [(Valor Produtos + IPI + Outras Depesas) x (CargaTribut/100)]
                   ----------------------------------------------------------------------------------------------
        		                                         (Aliq1/100)
                                                     
         Valor ST = [Valor Estimativa Simplificada Carga Tributária Média]
         
         OBS: Excluem-se deste: Cliente Regime Isenção; Item Bonificado Retira ST Estadual; Orgão Público e a Tributação tem Isenção de ST para Órgãos Públicos
         */
  
         /*--------------------------------------------------------------------------------------------
          DEFINIÇÃO DO VALOR DA OPERAÇÃO PRÓPRIA
          -------------------------------------*/
  
          -- Base Cálculo
          vnBcIcmsOperPropriaCargaTribut := NVL(vnPVENDA,0); 
          -- Valor
          vnVlIcmsOperPropriaCargaTribut := NVL(vnBcIcmsOperPropriaCargaTribut,0) * (NVL(p_ALIQICMS2FONTE,0) / 100);
          
         /*--------------------------------------------------------------------------------------------
          DEFINIÇÃO DO ST VALOR DA OPERAÇÃO PRÓPRIA
          -------------------------------------*/
  
          -- Base Cálculo
          vnBcEstimatSimplifCargaTribut := NVL(vnPVENDA,0);
          vnBcEstimatSimplifCargaTribut := NVL(vnBcEstimatSimplifCargaTribut,0) + NVL(p_vlipi,0);
          vnBcEstimatSimplifCargaTribut := NVL(vnBcEstimatSimplifCargaTribut,0) + NVL(p_vlfreteoutrasdesp,0);
          -- Valor
          vnVlEstimatSimplifCargaTribut := NVL(vnBcEstimatSimplifCargaTribut,0) * (NVL(p_PERCREGSIMPLCARGATRIBSTFONTE,0) / 100);
  
         /*--------------------------------------------------------------------------------------------
          DEFINIÇÃO DA BASE DO ST
          ----------------------*/
          
          vnBCST := (NVL(vnVlIcmsOperPropriaCargaTribut,0) + NVL(vnVlEstimatSimplifCargaTribut,0)) / (NVL(p_ALIQICMS1FONTE,0) / 100);
  
         /*--------------------------------------------------------------------------------------------
          DEFINIÇÃO DO VALOR DO ST
          -----------------------*/
          
          vnSTFONTE := NVL(vnVlEstimatSimplifCargaTribut,0);
          
          --Calcular ST - Truncar com 2 casas decimais
          IF p_tipocalcst = 'T2' THEN
            vnstfonte := trunc((vnstfonte) * 100) / 100;
          ELSIF p_tipocalcst = 'A2' THEN
            vnstfonte := round((vnstfonte) * 100) / 100;
          ELSIF p_tipocalcst = 'PV' THEN
            vnSTFONTE := round(vnSTFONTE, p_numcasasdecvenda);       
          END IF;
          
       /*********************************************************************************************
        *********************************************************************************************
        **                          CALCULAR VALOR DO ST FONTE [RBD04]                             **
        *********************************************************************************************
        *********************************************************************************************/
        ELSIF (vbCalculaSTFonte) THEN
          
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',Padrão';
                
         /*--------------------------------------------------------------------------------------------
          DEFINIÇÃO DA REDUÇÃO DA BASE DE CÁLCULO
          --------------------------------------*/
        
          vnpercbasered := p_percbaseredstfonte;
        
          -- MED-1080 - Redução da Base Crédito do ST Fonte
          vnpercbaseredBaseCred := p_percbaseredstfonte;
          IF (NVL(p_USAREDICMNORMVENDASTFONTE,'N') = 'S') THEN
            vnpercbaseredBaseCred := p_PERCBASERED; -- MED-1080
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',RedICMSNorm'||p_PERCBASERED;
          END IF;
        
          --  MED-2346 - Redução para o ICMS Crédito
          vnpercbaseredIcmsFecp := p_PERCBASERED; 
        
          ---- Se tipo de empresa do cliente for Normal RPA
          ---- Aplicar %reducao na base de ICMS especifico
          IF (p_tipoempresa = 'NRPA') THEN
            vnpercbasered         := p_percbaserednrpa;
            vnpercbaseredBaseCred := p_percbaserednrpa; -- MED-1080
            vnpercbaseredIcmsFecp := p_percbaserednrpa; -- MED-2346
            
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',NRPA';
          END IF;
          ---- Cliente consumidor final utiliza %base red. p/ consumidor final
          IF (p_consumidorfinal = 'S') AND (p_percbaseredconsumidor <> 0) THEN
            vnpercbasered         := p_percbaseredconsumidor;
            vnpercbaseredBaseCred := p_percbaseredconsumidor; -- MED-1080
            vnpercbaseredIcmsFecp := p_percbaseredconsumidor; -- MED-2346
            
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',Red.CF';
          END IF;
          ---- Cliente PF que utiliza IE simplificada nao aplica %base red
          IF (p_utilizaiesimplificada = 'S') AND (p_tipofj = 'F') AND
             (p_contribuinte = 'N') THEN
            vnpercbasered         := 0;
            vnpercbaseredBaseCred := 0; -- MED-1080
            vnpercbaseredIcmsFecp := 0; -- MED-2346
            
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',PF.Simplif.';
          END IF;
        
          if vbpessoafisica = true then
            if (p_UTILIZAPERCBASEREDPF = 'N') or
               (p_UTILIZAPERCBASEREDPF_TRIB = 'N') then
              vnPERCBASERED         := 0;
              vnpercbaseredBaseCred := 0; -- MED-1080
              vnpercbaseredIcmsFecp := 0; -- MED-2346
              
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',Red.PF.';
            end if;
          end if;
        
          IF (p_isentoicms = 'S') OR (p_condvenda = 7) THEN
            vnpercbasered         := 0;
            vnpercbaseredBaseCred := 0; -- MED-1080
            vnpercbaseredIcmsFecp := 0; -- MED-2346
            
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',Red.Isento';
          END IF;
          
          --// MERGE CR -> GU = Farmácia Popular não tem Redução da Base de Cálculo
          if (vbRegraFciaPopular) then
            vnpercbasered         := 0;
            vnpercbaseredBaseCred := 0; -- MED-1080
            vnpercbaseredIcmsFecp := 0; -- MED-2346
            
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',Red.FciaPop.';
          end if;
  
          --// MED-2428
          IF (vbUsaPmcBaseSt) THEN
            IF (p_usaReducaoBasePmc = 'S') AND (p_pertetoredbasepmc > 0) THEN
              IF (NVL(p_pvenda,0) > 0) THEN
                IF ((p_pvenda / P_PRECOMAXCONSUM * 100) >= p_pertetoredbasepmc)  THEN
                  vnpercbasered         := 0;
                  vnpercbaseredBaseCred := 0; -- MED-1080
                  vnpercbaseredIcmsFecp := 0; -- MED-2346
                  -- Observação ST Fonte
                  p_observacaostfonte := p_observacaostfonte || ',Sem Red.Teto PMC.';
                END IF;
              END IF;
            END IF;
          END IF;
  
  
          p_percbaseredstfonte := vnpercbasered;
        
         /*--------------------------------------------------------------------------------------------
          DEFINIÇÃO DO PERCENTUAL DE IVA FONTE
          -----------------------------------*/
        
          -- Definir IVA do ST Fonte [RBD07]
          if p_UsaIVAFonteDiferenciado = 'N' then
            vnIvaFonte := p_IVAFONTE;
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',N:Iva Dif.';
          
            --Comentado na 316 por:  //Fernandes 13/09/2011
            --if vnIVAFONTE = 0  and 
            --   not ((nvl(p_PRECOMAXCONSUM,0) > 0) and (NVL(p_USAPMCBASEST,'N') = 'S')) then
            --  p_ALIQICMS1FONTE := 0;
            --  p_ALIQICMS2FONTE := 0;
            --end if;
            --Fim Comentado na 316 por:  //Fernandes 13/09/2011
          elsif p_usaivafontediferenciado = 'S' then
            vnIvaFonte := p_IVAFonte_Cli;
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',S:Iva Dif.';
            
          elsif p_usaivafontediferenciado = 'M' then
          
            if p_IVAFONTE > p_IVAFonte_Cli then
              vnIVAFONTE := p_IVAFONTE;
            else
              vnIvaFonte := p_IVAFonte_Cli;
            end if;
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',M:Iva Dif.';
            
          end if;
        
          -- [HIS.05161.2014] - Redução Simples Nacional no IVA
          IF (p_somenteIVATribut = 'N') THEN
            IF ((NVL(p_usadescsimplesnac,'N')     = 'N')     AND  -- Somente se na Rotina 132 Não usa desconto do Simples Nacional
                (NVL(p_percredpvendasimplesnac,0) > 0)       AND  -- Somente se tiver % Redução cadastrado na Tributação
                (NVL(p_simplesnacional,'N')       = 'S')     AND  -- Somente se o Cliente participa do Simples Nacional 
                (NVL(p_tipomerc,' ') NOT IN (' ','M','MA'))) THEN -- Somente se não for Medicamento e tiver o Tipo Merc. Preenchido
              vnIvaFonte := vnIvaFonte * (p_percredpvendasimplesnac / 100);
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',Red.Iva SN';
            END IF;          
          END IF;
        
         /*--------------------------------------------------------------------------------------------
          DEFINIÇÃO DA BASE DE CÁLCULO DA ALIQ 01
          --------------------------------------*/
            
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('Tipo de Base de Cálculo do ST (Débito)', 'COLUNA_BCST');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('1) Base ST pela Pauta Fonte (Farmácia Popular)', 'COLUNA_BCST', 'PAUTAFONTE');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('2) Base ST pelo Preço Máximo Consumidor', 'COLUNA_BCST', 'PMC');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('3) Base ST pelo Preço Tabela', 'COLUNA_BCST', 'PTABELA'); 
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('4) Base ST pela Média dos Valores das Entradas (MG)', 'COLUNA_BCST', 'VLMEDIAENTMG');                                                
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('5) Base ST pelo Custo da Nota de Entrada sem ST', 'COLUNA_BCST', 'CUSTONF');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('6) Base ST pelo Valor da Ultima Entrada', 'COLUNA_BCST', 'VALORULTENT');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('7) Base ST pelo Valor da Ultima Entrada (ST RJ)', 'COLUNA_BCST', 'VLULTENTSTRJ');
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('8) Base ST pelo Valor dos Produtos', 'COLUNA_BCST', 'PVENDA');   
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('9) Base ST pelo PMPF', 'COLUNA_BCST', 'PMPF');          
            
          -- FARMACIA POPULAR
          if    (vbRegraFciaPopular) then 
             
             vnPBASE := NVL(p_PAUTAFONTE,0);         
  
             vnVlFreteOutrasDespBaseSt   := NVL(p_vlfreteoutrasdesp,0);
             vnVlFreteOutrasDespBaseIcms := NVL(p_vlfreteoutrasdesp,0);
  
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',FciaPop';
             
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('COLUNA_BCST', 'PAUTAFONTE');                     
    
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Valor Inicial da Base ST (Débito)', vnPBASE);
    
          -- PMC NA BASE DO ST
          elsif (vbUsaPmcBaseSt) then
    
             vnPBASE := P_PRECOMAXCONSUM; 
  
             vnVlFreteOutrasDespBaseSt := 0; --> Nesta Regra não aplicará Frete e Outras Despesas
             
             -- HIS.03428.2017 - CONFORME NOVA LEGISLAÇÃO, SEMPRE SOMARÁ NO ICMS PRÓPRIO           
             vnVlFreteOutrasDespBaseIcms := NVL(p_vlfreteoutrasdesp,0);
  
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',PMC';
             
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('COLUNA_BCST', 'PMC');                     
             
             -- Memória de Cálculo
             P_INSERIR_MEMORIA_CALCULO('=', 'Valor Inicial da Base ST (Débito)', vnPBASE);
             

          -- PMPF NA BASE DO ST
          elsif (vbUsaPmPfBaseSt) then
    
             vnPBASE  := P_PMPF; 
             
             po_nPmPf := P_PMPF; -- DDMEDICA-7697
  
             vnVlFreteOutrasDespBaseSt := 0; --> Nesta Regra não aplicará Frete e Outras Despesas
             
             vnVlFreteOutrasDespBaseIcms := NVL(p_vlfreteoutrasdesp,0);
  
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',PMPF';
             
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('COLUNA_BCST', 'PMPF');                     
             
             -- Memória de Cálculo
             P_INSERIR_MEMORIA_CALCULO('=', 'Valor Inicial da Base ST (Débito)', vnPBASE);
             
          -- USAR PTABELA BASE DO ST
          elsif (NVL(p_usaptabelabasest,'N') = 'S') then
          
             vnPBASE := p_ptabela;
  
             vnVlFreteOutrasDespBaseSt   := NVL(p_vlfreteoutrasdesp,0);
             vnVlFreteOutrasDespBaseIcms := NVL(p_vlfreteoutrasdesp,0);
             
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',P.Tab';
             
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('COLUNA_BCST', 'PTABELA');                     
             
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Valor Inicial da Base ST (Débito)', vnPBASE);
                                       
          -- USAR VALOR MÉDIO DAS ULTIMAS ENTRADAS (MG)
          elsif (NVL(p_usavlultentmediobasest,'N') = 'S') then
  
             vnPBASE := p_vlultentmes;
  
             vnVlFreteOutrasDespBaseSt   := NVL(p_vlfreteoutrasdesp,0);
             vnVlFreteOutrasDespBaseIcms := NVL(p_vlfreteoutrasdesp,0);
             
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',Media Ent.MG';
             
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('COLUNA_BCST', 'VLMEDIAENTMG');                     
             
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Valor Inicial da Base ST (Débito)', vnPBASE);
             
          -- DEMAIS CASOS (PVENDA, CUSTO, ETC)              
          else
        
            -- DDMEDICA-7594 - Passou para o inicio por ser prioritário sobre todos os ValorUltEnt
            if (p_UfFilial = p_EstEnt) and (NVL(p_UsaValorUltEntBaseST2,'N') = 'S') then
            
              vnPVENDA := vnCustoNFSemST; 
              
              vnVlFreteOutrasDespBaseSt   := 0; --> Nesta Regra não aplicará Frete e Outras Despesas
              vnVlFreteOutrasDespBaseIcms := 0;
               
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',Ult.Ent.ST2';
              
            -- VALOR DA ULTIMA ENTRADA NA BASE DO ST      
            ELSIF (p_uffilial = p_estent) AND
                  (nvl(p_usavalorultentbasest, 'N') = 'S') AND
                  (NVL(p_percbasestrj,0) = 0) THEN
               
              vnpbase  := vncustonfsemst; 
    
              vnVlFreteOutrasDespBaseSt   := NVL(p_vlfreteoutrasdesp,0);
              vnVlFreteOutrasDespBaseIcms := 0;
              
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',Ult.Ent.';
              
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             if nvl(P_CUSTONFSEMST,0) = 0 then
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('COLUNA_BCST', 'VALORULTENT');                     
                                                                                                                                             ELSE            
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('COLUNA_BCST', 'CUSTONF');                     
                                                                                                                                             END IF;
  
            -- VALOR DA ULTIMA ENTRADA NA BASE DO ST - RJ (RIO DE JANEIRO)
            ELSIF (p_uffilial = p_estent) AND
                  (nvl(p_usavalorultentbasest, 'N') = 'S') AND
                  (NVL(p_percbasestrj,0) > 0) THEN
  
              vnpbase  := NVL(p_valorultent,0); 
    
              vnVlFreteOutrasDespBaseSt   := 0; --> VERIFICAR DEPOIS Nesta Regra não aplicará Frete e Outras Despesas
              vnVlFreteOutrasDespBaseIcms := 0;
              
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',Ult.Ent.RJ';
              
                                                                                                                         -- Memória de Cálculo
                                                                                                                         P_ATU_OPCAO_MEMORIA_CALCULO('COLUNA_BCST', 'VLULTENTSTRJ');                     
                          
            ELSE          
            
              vnpbase := p_pvenda;
    
              vnVlFreteOutrasDespBaseSt   := NVL(p_vlfreteoutrasdesp,0);
              vnVlFreteOutrasDespBaseIcms := NVL(p_vlfreteoutrasdesp,0);
              
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',P.Venda';            
              
                                                                                                                         -- Memória de Cálculo
                                                                                                                         P_ATU_OPCAO_MEMORIA_CALCULO('COLUNA_BCST', 'PVENDA');                     
                                                               

              ---------------------------------------------------------------------------------------------------
              -- DDMEDICA-7594 - Valores para Customização da Base ST com SUFRAMA/Redução PISCOFINS e DESONERACAO
              -- Base ST da Alíquota 1
              ---------------------------------------------------------------------------------------------------
              -- Usou IVA na Base 1
              vbUsouIVAFonte_B1 := TRUE;

              -- Define os Valores conforme parametrização
              IF (p_agregapiscofinsst1 = 'S') THEN
                vnVlDescReducaoPisCofins_B1 := (NVL(p_vldescreducaopis,0) + NVL(p_vldescreducaocofins,0));
              END IF; 
              IF (p_agregasuframast1 = 'S') THEN 
                vnVlDescSuframaPisSuframa_B1 := NVL(p_vldescsuframa,0);
              END IF;
              IF (p_agregaicmsisencaost1 = 'S') THEN
                vnVlDescIcmIsencao_B1        := NVL(p_vldescicmisencao,0);
              END IF;
              
              -- APLICA REDUÇÃO PIS/COFINS
              IF (NVL(vnVlDescReducaoPisCofins_B1,0) > 0) THEN
                vnPBASE := NVL(vnPBASE,0) - NVL(vnVlDescReducaoPisCofins_B1,0);        
              
                                                                                                                                                 -- Memória de Cálculo          
                                                                                                                                                 P_INSERIR_MEMORIA_CALCULO('-', 'Redução PIS/COFINS', vnPBASE, NULL, vnVlDescReducaoPisCofins_B1);
                                                                                                                                                 
              END IF; 
              
              -- APLICA REDUÇÃO SUFRAMA
              IF (NVL(vnVlDescSuframaPisSuframa_B1,0) > 0) THEN
                vnPBASE := NVL(vnPBASE,0) - NVL(vnVlDescSuframaPisSuframa_B1,0);        
              
                                                                                                                                                 -- Memória de Cálculo          
                                                                                                                                                 P_INSERIR_MEMORIA_CALCULO('-', 'Redução SUFRAMA', vnPBASE, NULL, vnVlDescSuframaPisSuframa_B1);
                                                                                                                                                 
              END IF; 
    
              -- APLICA REDUÇÃO DESONERAÇÃO
              IF (NVL(vnVlDescIcmIsencao_B1,0) > 0) THEN
                vnPBASE := NVL(vnPBASE,0) - NVL(vnVlDescIcmIsencao_B1,0);        
              
                                                                                                                                                 -- Memória de Cálculo          
                                                                                                                                                 P_INSERIR_MEMORIA_CALCULO('-', 'Redução Desoneração ICMS', vnPBASE, NULL, vnVlDescIcmIsencao_B1);
                                                                                                                                                 
              END IF; 
              ---------------------------------------------------------------------------------------------------

            END IF;


                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Valor Inicial da Base ST (Débito)', vnPBASE);
        
            -- Soma o Valor do IPI na Base do ST
            vnpbase := vnpbase + nvl(p_vlipi, 0);
            
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('+', 'IPI', vnPBASE, p_percipivenda, p_vlipi);
            
         
          end if;
          
          -- APLICA VALOR DO FRETE E OUTRAS DESPESAS na Base de Cáculo Aliq. 01
          vnPBASE := NVL(vnPBASE,0) + NVL(vnVlFreteOutrasDespBaseSt,0);        
          
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('+', 'Frete e Outras Despesas', vnPBASE, NULL, vnVlFreteOutrasDespBaseSt);
          
          
          -- Guarda a Base ST Original sem Redução para cálculos mais abaixo - 5661.146071.2016
          vnBaseStOriginalSemReducao := vnPBASE;         
             
          --------------------------------------------
          -- APLICA REDUÇÃO na Base de Cáculo Aliq. 01
          --------------------------------------------
          
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('Aplicar Redução na Base de ST (Débito) ?', 'RED_BCST');                
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('1) Sim, aplicar redução', 'RED_BCST', 'SIM');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('2) Não aplicar redução', 'RED_BCST', 'NAO');          
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('RED_BCST', 'NAO'); -->> Default               
          
          -- Se tem Redução na Base do ST
          IF vnpercbasered > 0 THEN
          
                                                                                                                                             -- Variáveis Auxiliares da Memória de Calculo
                                                                                                                                             vnPercMemoriaCalculo           := (100 - vnpercbasered);
                                                                                                                                             vnValorCalculadoMemoriaCalculo := (vnpbase * (vnPercMemoriaCalculo / 100));
          
            -- Aplica Redução na Base
            vnpbase := vnpbase * (vnpercbasered / 100);
            
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('RED_BCST', 'SIM');                     
            
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('-', 'Redução de ' || vnpercbasered || '% na Base ST (Crédito)', vnPBASE, vnPercMemoriaCalculo, vnValorCalculadoMemoriaCalculo);
            
          END IF; -- Fim Condição: APLICA REDUÇÃO na Base de Cáculo Aliq. 01
          
          ---------------------------------------------        
          -- APLICA O REDUTOR Cat/49 - 5661.146071.2016
          ---------------------------------------------        
          
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('Aplicar Redução Cat-49/2016 na Base de ST (Débito) ?', 'CAT49_BCST');                
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('1) Sim, aplicar Cat-49/2016', 'CAT49_BCST', 'SIM');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('2) Não aplicar Cat-49/2016','CAT49_BCST', 'NAO');          
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('CAT49_BCST', 'NAO'); -->> Default               
                  
          -- Se usa Redutor Cat/49
          IF (p_USAREDUTORCAT49BASESTFONTE = 'S') THEN
            IF (NVL(p_PERCREDUTORCAT49BASESTFONTE,0) > 0) THEN
  
                                                                                                                                             -- Variáveis Auxiliares da Memória de Calculo
                                                                                                                                             vnPercMemoriaCalculo           := (100 - p_PERCREDUTORCAT49BASESTFONTE);
                                                                                                                                             vnValorCalculadoMemoriaCalculo := (vnpbase * (vnPercMemoriaCalculo / 100));
            
              -- Aplica Redução CAT/49 na Base
              vnpbase := vnpbase * (NVL(p_PERCREDUTORCAT49BASESTFONTE,0) / 100);
              
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',Red.Cat49';
              
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('CAT49_BCST', 'SIM');                     
              
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('-', 'Redução Cat/49 de ' || vnpercbasered || '% da Base ST', vnPBASE, vnPercMemoriaCalculo, vnValorCalculadoMemoriaCalculo);                                                  
              
            END IF;
          END IF;
                            
          ---------------------------------------------------------------------------------------------      
          -- Regra Ajuste de Preço CMED para o PMC
          -- (Tributação Marcada para Ajuste de Preço CMED, se tiver PMC e se Não for Farmácia Popular)
          ---------------------------------------------------------------------------------------------      
          
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('Aplicar Legislação Cat-35/2014 na Base de ST (Débito) ? (Obs: Somente Produtos com PMC e sem Pauta)', 'CAT35_BCST');                
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('1) Aplicar Cat-35/2014 ajustando a Base de ST pelo MVA (Fator Ajuste CMED >= Percentual de Referência)', 'CAT35_BCST', 'SIM_MVA_REF');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('2) Aplicar Cat-35/2014 ajustando a Base de ST pelo PMC (Fator Ajuste CMED >= Percentual de Referência)', 'CAT35_BCST', 'SIM_PMC_REF');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('3) Aplicar Cat-35/2014 ajustando a Base de ST pelo PMC (Fator Ajuste CMED < Percentual de Referência)', 'CAT35_BCST', 'SIM_PMC');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('4) Não Aplicar Legislação Cat-35/2014', 'CAT35_BCST', 'NAO');          
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('CAT35_BCST', 'NAO'); -->> Default               
          
          -- Se Utilizar Legislação Cat/35 (Ajuste Preço CMED
          IF (NVL(p_usarajusteprecocmed,'N') = 'S') AND
             (NVL(p_PRECOMAXCONSUM,0) > 0) AND
             (NOT vbRegraFciaPopular) THEN
                       
            -- PMC de Referência para Ajuste Preço CMED
            IF (NVL(vnpercbasered,0) > 0) THEN
            
              vnPmcAjustePrecoCMED := NVL(p_PRECOMAXCONSUM,0) * (vnpercbasered / 100);
              
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',Red.AjusteCMED';
                          
            ELSE
            
              vnPmcAjustePrecoCMED := NVL(p_PRECOMAXCONSUM,0);
                          
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',AjusteCMED';
                          
            END IF;
                                  
            -- Se o Preço de Venda passado no Parâmetro sobre o PMC com Redução exceder o Percentual informado na Tributação,
            -- calcula a Base de ST pelo MVA mesmo sendo um Produto Tributado pelo PMC
            IF (((NVL(p_pvenda,0) / NVL(vnPmcAjustePrecoCMED,0)) * 100) >= NVL(p_percajusteprecocmed,0)) THEN
                                                 
              --- Calcula a base pelo MVA , sem o Percentual de Redução          
              vnBCST := NVL(p_pvenda,0) + nvl(p_vlipi,0);
              vnBCST := (vnBCST * (p_PERCVENDA / 100)) *
                        (1 + (vnIVAFONTE / 100));          
            
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',IVA AjusteCMED';
                                    
              -- A Base do ST não pode Exceder o PMC
              IF (NVL(vnBCST,0) > NVL(p_PRECOMAXCONSUM,0)) THEN
              
                vnBCST := NVL(p_PRECOMAXCONSUM,0);
                
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',Exc.AjusteCMED';
               
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('CAT35_BCST', 'SIM_PMC_REF');                     
               
              ELSE
              
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('CAT35_BCST', 'SIM_MVA_REF');                     
                           
              END IF;
                                    
            -- Sem Regra Ajuste Preço CMED
            ELSE
                      
              -- Calcula a Base do ST pelo PMC
              vnBCST := NVL(p_PRECOMAXCONSUM,0);
              -- Base de Cáculo Aliq. 01
              IF vnpercbasered > 0 THEN
                vnBCST := vnBCST * (vnpercbasered / 100);
              END IF;
              
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',S/AjusteCMED';
              
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('CAT35_BCST', 'SIM_PMC');                                 
              
            END IF;
            
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Percentual de Referência CAT/35', NULL, p_percajusteprecocmed, NULL);                                                  
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Fator Ajuste CMED ((Valor Produto ' || NVL(p_pvenda,0) || CHR(247) || ' PMC ' || NVL(vnPmcAjustePrecoCMED,0) || ') x 100)', NULL, NULL, ((NVL(p_pvenda,0) / NVL(vnPmcAjustePrecoCMED,0)) * 100)); 
                                      
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Substituição da Base ST conforme Legislação CAT-35/2014', vnBCST, NULL, NULL);                                                  
                                                                                                  
          -----------------------------------------------
          -- Demais Casos (FARMACIA POPULAR, PMC, MVA ...
          -----------------------------------------------
          ELSE
        
            -- FARMACIA POPULAR
            if (vbRegraFciaPopular) then
            
              -- Sem IVA
              vnBCST               := vnpbase;
              p_pautafonteaplicado := NVL(p_PAUTAFONTE,0); -- HIS.01838.2017
      
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte  := p_observacaostfonte || ',BaseFciaPop.';
      
            -- PMC NA BASE ST
            elsif (vbUsaPmcBaseSt) then
      
              -- Sem IVA
              vnBCST := vnpbase;
  
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte  := p_observacaostfonte || ',BasePMC';
              

            -- PMPF NA BASE ST
            elsif (vbUsaPmPfBaseSt) then
      
              -- Sem IVA
              vnBCST := vnpbase;
  
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte  := p_observacaostfonte || ',BasePMPF';              

            -- Demais casos: COM IVA
            else
      
              -- Variáveis Auxiliares da Memória de Calculo
              vnValorCalculadoMemoriaCalculo := (vnPBASE * (vnIVAFONTE / 100));
      
              -- Agrega o MVA na Base do ST
              vnBCST := (vnPBASE * (p_PERCVENDA / 100)) *
                        (1 + (vnIVAFONTE / 100));
                        
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte  := p_observacaostfonte || ',BaseIVA';
              
                                                                                                                                                         -- Memória de Cálculo          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('Aplicar MVA na Base de ST (Débito)', 'MVA_BCST');                
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('1) Sim, aplicar MVA', 'MVA_BCST', 'SIM');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('2) Não aplicar MVA', 'MVA_BCST', 'NAO');   
                                                                                                                                             IF (vnIVAFONTE > 0) THEN       
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('MVA_BCST', 'SIM'); -->> Default               
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('+', 'MVA', vnBCST, vnIVAFONTE, vnValorCalculadoMemoriaCalculo);                                          
                                                                                                                                             END IF;
                                                                
            end if;
            
          END IF;
                            
          -- Valor Aliq. 01 --
          --------------------
          vnSTF1 := vnBCST * (p_ALIQICMS1FONTE / 100);
          
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('>', 'Valor ICMS Compra (Débito)', NULL, p_ALIQICMS1FONTE, vnSTF1);
          
          -- Valores para gravação do ST recolhido anteriormente -
          --------------------------------------------------------
          po_vEnquadraIcmsSubstAnterior := 'S'; -- DDVENDAS-32054
         
         /*--------------------------------------------------------------------------------------------
          DEFINIÇÃO DA BASE DE CALCULO DA ALIQ 02
          --------------------------------------*/
          
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('Tipo de Base de Cálculo do ICMS (Crédito)', 'COLUNA_BCICM');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('1) Base ICMS pelo Preço Tabela', 'COLUNA_BCICM', 'PTABELA');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('2) Base ICMS pela Média dos Valores das Entradas (MG)', 'COLUNA_BCICM', 'VLULTENTMES');                          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('3) Base ICMS pelo Valor dos Produtos', 'COLUNA_BCICM', 'PVENDA');          
                  
          -------------------------------------------------------------------------------------
          -- Base de Cáculo Aliq. 02
          -- Se Usa o Preço Tabela na Base do ST, aplica o PTabela também na Base da Alíquota 2
          -------------------------------------------------------------------------------------
          
          -- Se Utiliza Preço Tabela na Base do ST        
          IF (NVL(p_usaptabelabasest,'N') = 'S') THEN
          
            vnPVENDA := p_ptabela;
  
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte  := p_observacaostfonte || ',BaseIcmPTab.';          
            
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('COLUNA_BCICM', 'PVENDA');                                           
          
          -- Se Utiliza a Média dos Valores das Entradas (MG)
          ELSIF (NVL(p_usavlultentmediobasest,'N') = 'S') THEN
  
            vnPVENDA := p_vlultentmes;
  
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte  := p_observacaostfonte || ',BaseIcm Media MG';          
            
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('COLUNA_BCICM', 'VLULTENTMES');                                           
          
          -- Se Utiliza o Preço de Venda 
          ELSE
  
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte  := p_observacaostfonte || ',BaseIcmPVenda.';          
          
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('COLUNA_BCICM', 'PVENDA');                                 
          
          END IF;      
            
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Valor Inicial da Base ICMS (Crédito)', vnPVENDA);


          ---------------------------------------------------------------------------------------------------
          -- DDMEDICA-7594 - Valores para Customização da Base ST com SUFRAMA/Redução PISCOFINS e DESONERACAO
          -- Base ST da Alíquota 2
          ---------------------------------------------------------------------------------------------------
          -- Somente se usou IVA na Base 1
          IF (vbUsouIVAFonte_B1) THEN
          
            -- Define os Valores conforme parametrização
            IF (p_agregapiscofinsst2 = 'S') THEN
              vnVlDescReducaoPisCofins_B2 := (NVL(p_vldescreducaopis,0) + NVL(p_vldescreducaocofins,0));
            END IF; 
            IF (p_agregasuframast2 = 'S') THEN 
              vnVlDescSuframaPisSuframa_B2 := NVL(p_vldescsuframa,0);
            END IF;
            IF (p_agregaicmsisencaost2 = 'S') THEN
              vnVlDescIcmIsencao_B2        := NVL(p_vldescicmisencao,0);
            END IF;
  
            -- APLICA REDUÇÃO PIS/COFINS
            IF (NVL(vnVlDescReducaoPisCofins_B2,0) > 0) THEN
              vnPVENDA := NVL(vnPVENDA,0) - NVL(vnVlDescReducaoPisCofins_B2,0);        
            
                                                                                                                                               -- Memória de Cálculo          
                                                                                                                                               P_INSERIR_MEMORIA_CALCULO('-', 'Redução PIS/COFINS', vnPVENDA, NULL, vnVlDescReducaoPisCofins_B2);
                                                                                                                                               
            END IF; 
            
            -- APLICA REDUÇÃO SUFRAMA
            IF (NVL(vnVlDescSuframaPisSuframa_B2,0) > 0) THEN
              vnPVENDA := NVL(vnPVENDA,0) - NVL(vnVlDescSuframaPisSuframa_B2,0);        
            
                                                                                                                                               -- Memória de Cálculo          
                                                                                                                                               P_INSERIR_MEMORIA_CALCULO('-', 'Redução SUFRAMA', vnPVENDA, NULL, vnVlDescSuframaPisSuframa_B2);
                                                                                                                                               
            END IF; 
  
            -- APLICA REDUÇÃO DESONERAÇÃO
            IF (NVL(vnVlDescIcmIsencao_B2,0) > 0) THEN
              vnPVENDA := NVL(vnPVENDA,0) - NVL(vnVlDescIcmIsencao_B2,0);        
            
                                                                                                                                               -- Memória de Cálculo          
                                                                                                                                               P_INSERIR_MEMORIA_CALCULO('-', 'Redução Desoneração ICMS', vnPVENDA, NULL, vnVlDescIcmIsencao_B2);
                                                                                                                                               
            END IF; 
          END IF;
          ---------------------------------------------------------------------------------------------------
            
          ---------------------------------------------------------------------
          -- APLICA VALOR DO FRETE E OUTRAS DESPESAS na Base de Cáculo Aliq. 02
          ---------------------------------------------------------------------
  
          -- APLICA VALOR DO FRETE E OUTRAS DESPESAS na Base de Cáculo Aliq. 02
          vnPVENDA := NVL(vnPVENDA,0) + NVL(vnVlFreteOutrasDespBaseIcms,0);        
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('+', 'Frete e Outras Despesas', vnPVENDA, NULL, vnVlFreteOutrasDespBaseIcms);
            
          ---------------------------------------------
          -- Se usa Base ICMS Reduzida no Cálculo do ST
          ---------------------------------------------
          
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('Aplicar Redução na Base de ICMS (Crédito) ?', 'RED_BCICM');                
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('1) Sim, reduzir a base usando o Percentual Redução do ST Fonte', 'RED_BCICM', 'SIM_REDFONTE');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('2) Sim, reduzir a base usando o Percentual Redução do ICMS da Venda', 'RED_BCICM', 'SIM_REDVENDA');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('3) Não reduzir a base', 'RED_BCICM', 'NAO');          
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('RED_BCICM', 'NAO'); -->> Default               
          
          -- Se usa Base ICMS Reduzida
          IF (p_usabaseicmsreduzida = 'S') THEN
            
            -- MED-1080 - Redução da Base Crédito do ST Fonte
            IF (NVL(p_USAREDICMNORMVENDASTFONTE,'N') = 'S') THEN
              
              IF vnpercbaseredBaseCred > 0 THEN
               
                                                                                                                                             -- Variáveis Auxiliares da Memória de Calculo
                                                                                                                                             vnPercMemoriaCalculo           := (100 - vnpercbaseredBaseCred);
                                                                                                                                             vnValorCalculadoMemoriaCalculo := (vnpbase * (vnPercMemoriaCalculo / 100));
               
                -- Aplica Redução da Alíquota informada na Aba de ICMS na Venda
                vnPVENDA := vnPVENDA * (vnpercbaseredBaseCred / 100);
  
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte  := p_observacaostfonte || ',Red.PVenda'||vnpercbaseredBaseCred;          
  
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('RED_BCICM', 'SIM_REDVENDA');                                               
                                            
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('-', 'Redução de ' || vnpercbaseredBaseCred || '% na Base de ICMS (Débito)', vnPVENDA, vnPercMemoriaCalculo, vnValorCalculadoMemoriaCalculo);
                                            
              END IF;
              
            ELSE
                        
              IF vnpercbasered > 0 THEN
              
                                                                                                                                             -- Variáveis Auxiliares da Memória de Calculo
                                                                                                                                             vnPercMemoriaCalculo           := (100 - vnpercbasered);
                                                                                                                                             vnValorCalculadoMemoriaCalculo := (vnpbase * (vnPercMemoriaCalculo / 100));
              
                -- Aplica Redução da Alíquota informada na Aba de ST Fonte
                vnPVENDA := vnPVENDA * (vnpercbasered / 100);
              
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte  := p_observacaostfonte || ',Red.PVenda';          
              
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('RED_BCICM', 'SIM_REDFONTE');                                 
                                            
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('-', 'Redução de ' || vnpercbasered || '% na Base de ICMS (Débito)', vnPVENDA, vnPercMemoriaCalculo, vnValorCalculadoMemoriaCalculo);
                                            
              END IF;
              
            END IF;
          END IF;
  
          -- Se Item Bonificado e a Bonificação não calcular ICMS
          IF ((p_itembonific IN ('S','F')) and -- DDMEDICA-198 - Incluir F
              (p_bnfnaocalculaicms = 'S')) THEN
            p_ALIQICMS2FONTE := 0;
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte  := p_observacaostfonte || ',BNF';          
          END IF;
            
          -- Valor Aliq. 02 --
          --------------------
          vnSTF2 := (vnPVENDA * (p_PERCVENDA / 100)) *
                    (p_ALIQICMS2FONTE / 100);
                                 
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('>', 'Valor ICMS Venda (Crédito)', NULL, p_ALIQICMS2FONTE, vnSTF2);

          -- Valores para gravação do ST recolhido anteriormente -
          --------------------------------------------------------
          po_nVlIcmsSubstitutoAnterior  := vnSTF2; -- DDVENDAS-32054

         /*--------------------------------------------------------------------------------------------
          CALCULO DO ST FONTE
          ------------------*/
                       
          -- ST FONTE
          vnSTFONTE := vnSTF1 - vnSTF2;
        
          --Calcular ST - Truncar com 2 casas decimais
          IF p_tipocalcst = 'T2' THEN
            vnstfonte := trunc((vnstfonte) * 100) / 100;
          ELSIF p_tipocalcst = 'A2' THEN
            vnstfonte := round((vnstfonte) * 100) / 100;
          ELSIF p_tipocalcst = 'PV' THEN
            vnSTFONTE := round(vnSTFONTE, p_numcasasdecvenda);       
          END IF;
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('#', 'Valor ICMS ST (Valor ICMS Débito - Valor ICMS Crédito)', NULL, NULL, vnSTFONTE);
  
          --------------------------------------------------------
          -- CARGA MÍNIMA DEFERIMENTO ST FONTE - HIS.01277.2017 --
          --------------------------------------------------------
          
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('Usar Carga Mínima de Deferimento do ST Fonte ?', 'DEFERIM_ST');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('1) Sim, usar a carga mínima', 'DEFERIM_ST', 'SIM');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('2) Não usar a carga mínima', 'DEFERIM_ST', 'NAO');          
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('DEFERIM_ST', 'NAO'); -->> Default               
          
          -- Se usa Carga Mínima de ST Fonte
          IF (p_USACARGAMINIMADEFERIMSTFONTE = 'S') THEN
                         
            --Calculo o ST pela Carga Mínima
            vnStFonteCargaMinima := vnBCST * (NVL(p_PERCARGAMINIMADEFERIMSTFONTE,0) / 100) ;
                      
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Percentual de Carga Mínima de Deferimento ST Fonte', NULL, p_PERCARGAMINIMADEFERIMSTFONTE, NULL);                                                  
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Valor do ST Mínimo conforme Percentual de Defermimento', NULL, NULL, vnstfonte); 
            
            --Calcular ST pela Carga Mínima - Truncar com 2 casas decimais
            IF p_tipocalcst = 'T2' THEN
              vnStFonteCargaMinima := trunc((vnStFonteCargaMinima) * 100) / 100;
            ELSIF p_tipocalcst = 'A2' THEN
              vnStFonteCargaMinima := round((vnStFonteCargaMinima) * 100) / 100;
            ELSIF p_tipocalcst = 'PV' THEN
              vnStFonteCargaMinima := round(vnStFonteCargaMinima, p_numcasasdecvenda);       
            END IF;
                    
            -- Verifico se o ST do Item é inferior ao ST Calculado pela Carga Mínima
            IF (NVL(vnstfonte,0) < NVL(vnStFonteCargaMinima,0)) THEN
  
              -- Substitui ST
              vnstfonte := vnStFonteCargaMinima;
              
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('#', 'Substituição do Valor do ST conforme Deferimento ST Fonte', NULL, NULL, vnstfonte);                                                  
              
            END IF;
            
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',Carga Mín.';          
                                                        
          END IF; -- FIM: CARGA MÍNIMA DEFERIMENTO ST FONTE - HIS.01277.2017
        
          --Se ST for menor que 0, torná-lo 0
          IF vnstfonte < 0 THEN
            vnstfonte := 0;
          -- Não zerar a Base de Cálculo do ST se o resultado do ST for zero - HIS.03187.2015
          --ELSIF vnstfonte = 0 THEN
          --  vnbcst := 0;
          END IF;
          
          -- Se Usa o Preço Tabela na Base do ST, a Base de ST deverá ser o Preço de Tabela (ACRE)
          IF (NVL(p_usaptabelabasest,'N') = 'S') THEN
            vnbcst := p_ptabela;
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',PTab.BaseSt';                    
          END IF;      
        
          -- tarefa 53294
          IF nvl(p_aliqicms1fonte, 0) = 0 AND
             nvl(p_aliqicms2fonte, 0) = 0 THEN
            vnbcst := 0;
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',Zerada';
          END IF;            
  
          -------------------------------------------------------------------------
          -- PERCENTUAL BASE RJ - Priorização do Maior entre o Mínimo e o Calculado
          -------------------------------------------------------------------------
          
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('Opção de ST Mínimo RJ', 'VL_STRJ');                
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('1) Valor do ST calculado maior que o Valor do ST Mínimo RJ, manter ST calculado.', 'VL_STRJ', 'CALC_STRJ');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('2) Valor do ST calculado menor que o Valor do ST Mínimo RJ, substituir pelo ST Mínimo.', 'VL_STRJ', 'MIN_STRJ');   
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('3) Não aplicar ST Mínimo RJ', 'VL_STRJ', 'NAO_STRJ');   
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('VL_STRJ', 'NAO_STRJ'); -->> Default               
          
          IF (NVL(p_usavalorultentbasest,'N') = 'S') AND
             (NVL(p_percbasestrj,0) > 0)             THEN
  
            -- Base ST Rj pelo Valor da Última Entrada
            vnBaseStRj := NVL(p_valorultent,0);
  
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Valor Inicial da Base ST RJ', vnBaseStRj);
                                      
            -- Soma o Valor do IPI na Base do ST Rj
            vnBaseStRj := vnBaseStRj + nvl(p_vlipi, 0);
            
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('+', 'IPI', vnBaseStRj, p_percipivenda, p_vlipi);
                                      
            -- Agrega o MVA na Base do ST Rj
            vnBaseStRj := (vnBaseStRj * (1 + (vnIVAFONTE / 100)));
                                      
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('+', 'MVA', vnBaseStRj, vnIVAFONTE, vnValorCalculadoMemoriaCalculo);                                      
          
            -- Redução ST Rj
            vnPercBaseRedRj := NVL(vnpercbasered,0); 
            IF (NVL(vnPercBaseRedRj,0) = 0) THEN
              vnPercBaseRedRj := 100;
            END IF;
            
                                                                                                                                             -- Variáveis Auxiliares da Memória de Calculo
                                                                                                                                             vnPercMemoriaCalculo           := (100 - vnPercBaseRedRj);
                                                                                                                                             vnValorCalculadoMemoriaCalculo := (vnBaseStRj * (vnPercMemoriaCalculo / 100));
            
            -- Aplica Redução na Base do ST Rj
            vnBaseStRj := vnBaseStRj * (vnPercBaseRedRj / 100);
          
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('-', 'Redução de ' || vnPercBaseRedRj || '% na Base ST (Crédito)', vnBaseStRj, vnPercMemoriaCalculo, vnValorCalculadoMemoriaCalculo);
          
            -- Calcula o Valor do ST RJ  
            vnValorStRj := vnBaseStRj * (NVL(p_percbasestrj,0) / 100);
            
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('>', 'Valor Mínimo ST RJ', NULL, p_percbasestrj, vnValorStRj);
                                                                               
            -- Validação do ST Mínimo
            IF (NVL(vnstfonte,0) < NVL(vnValorStRj,0)) THEN
  
              -- Substitui a Base do ST 
              vnbcst    := NVL(vnBaseStRj,0); 
            
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Substituição da Base do ST conforme ST Mínimo RJ', NULL, NULL, vnbcst);                                                  
            
              -- Substitui o Valor do ST
              vnstfonte := NVL(vnValorStRj,0);
            
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('#', 'Substituição do Valor do ST conforme ST Mínimo RJ', NULL, NULL, vnstfonte);                                                  
                                                  
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('VL_STRJ', 'MIN_STRJ');                                 
  
            ELSE
               
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('VL_STRJ', 'CALC_STRJ');                                 
                                          
            END IF;
             
    
          END IF; -- Fim Condição: PERCENTUAL BASE RJ - Priorização do Maior entre o Mínimo e o Calculado
          
        END IF; -- FIM CONDIÇÃO CALCULA VALOR DO ST
              

        IF (NVL(p_utilizaCustoContBaseST,'N') = 'S') AND  (NVL(p_nFatorAjusteCustoCont,0) > 0) THEN
			  vnbcst := (NVL(vnPVENDA,0) +  NVL(p_vlfreteoutrasdesp,0));
			  P_INSERIR_MEMORIA_CALCULO('=', 'Substituição da Base do ST conforme ST pvenda + Despesas PB', NULL, NULL, vnbcst);

			  vnBaseSTPB := ((NVL(p_ncustocont,0)/(1-(p_nFatorAjusteCustoCont/100))) +  NVL(p_vlfreteoutrasdesp,0));
			  P_INSERIR_MEMORIA_CALCULO('#', 'Substituição da Base do ST conforme ST Custo Cont + Fator + Despesas PB', NULL, NULL, ROUND(vnBaseSTPB,p_numcasasdecvenda));    
					
			  vnstfonte  := vnbcst * (p_aliqicms1fonte/100);
					
			  vnStFonteCustoCont := vnBaseSTPB * (p_aliqicms1fonte/100);
			  IF (vnstfonte < vnStFonteCustoCont) THEN
				vnstfonte := vnStFonteCustoCont;
				vnbcst :=   vnBaseSTPB;
			  END IF;
			  --Calcular ST - Truncar com 2 casas decimais
			  IF p_tipocalcst = 'T2' THEN
				  vnstfonte := trunc((vnstfonte) * 100) / 100;
			  ELSIF p_tipocalcst = 'A2' THEN
				  vnstfonte := round((vnstfonte) * 100) / 100;
			  ELSIF p_tipocalcst = 'PV' THEN
				  vnSTFONTE := round(vnSTFONTE, p_numcasasdecvenda);
			  END IF;
			
			  P_INSERIR_MEMORIA_CALCULO('#', 'Substituição da Base do ST conforme Regime Especial PB', NULL, NULL, round(vnbcst,p_numcasasdecvenda));   
			  P_INSERIR_MEMORIA_CALCULO('#', 'Substituição conforme Regime Especial PB', NULL, NULL, vnstfonte);
			  IF nvl(p_aliqicms1fonte, 0) = 0 AND
			  nvl(p_aliqicms2fonte, 0) = 0 THEN
				vnbcst := 0;                                                           -- Observação ST Fonte
															   p_observacaostfonte := p_observacaostfonte || ',Zerada';
			  END IF;
			
		END IF;	   
       /*--------------------------------------------------------------------------------------------
        Atualização de Retornos adicionais
        ---------------------------------*/
  
        -- APLICA O REDUTOR Cat/49 - 5661.146071.2016
        IF (p_USAREDUTORCAT49BASESTFONTE = 'S') THEN
          -- Recalcula o % Redução, para considerar o agregado do % Red. Base Cálculo com o % Redutor Cat/49    
          IF (NVL(nPERCREDUTORCAT49BASESTFONTE,0) <> 0) AND
             (NVL(vnBaseStOriginalSemReducao,0) > 0)    THEN
            p_PercBaseRedStFonteAlterado := ROUND((NVL(vnbcst,0) / NVL(vnBaseStOriginalSemReducao,0)) * 100,4);
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',Redutor49';
          END IF;
        END IF;
              
        -- MED-2346 - Retorno das Outras Despesas que compõem a base de icms
        po_nVlFreteOutrasDespBaseIcms := vnVlFreteOutrasDespBaseSt;
        -- MED-2346 - Retorno do Percentual de Redução da Base de Icms
        po_nPercBaseRedIcmsFecp       := vnpercbaseredIcmsFecp;
			
        IF (NVL(p_USAVLSTMAIORPERCMINPMC, 'N') = 'S') AND
           (NVL(p_PERVLSTMAIORPERCMINPMC,0) > 0) AND
           (NVL(p_PRECOMAXCONSUM,0) > 0) THEN
		   
          vnStPercMinPMC := p_PRECOMAXCONSUM * p_PERVLSTMAIORPERCMINPMC / 100; 
          
          IF p_tipocalcst = 'T2' THEN
            vnStPercMinPMC := trunc((vnStPercMinPMC) * 100) / 100;
          ELSIF p_tipocalcst = 'A2' THEN
            vnStPercMinPMC := round((vnStPercMinPMC) * 100) / 100;
          ELSIF p_tipocalcst = 'PV' THEN
            vnStPercMinPMC := round(vnStPercMinPMC, p_numcasasdecvenda);       
          END IF;		   
		   
          IF vnStPercMinPMC > vnstfonte THEN
            vnstfonte := vnStPercMinPMC;
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('#', 'Substituição do Valor do ST conforme Percentual Minimo PMC', NULL, NULL, vnstfonte);                                                  			
          END IF;
        END IF;
              
       /*--------------------------------------------------------------------------------------------
        Retornos Base e Valor do ST
        --------------------------*/
        p_baseicst := vnbcst;  
        RETURN vnstfonte;
        
      EXCEPTION
        WHEN OTHERS THEN
          p_mensagem := 'Erro ao calcular STfonte: ' || SQLCODE || '-' ||
                        SQLERRM;
          RETURN 0;
      END FCALCULARSTFONTE;  
  
      -------------------------------------------------------------------------------------------------------------------
      -------------------------------------------------------------------------------------------------------------------
      -------------------------------------------------------------------------------------------------------------------
      -- FUNCTION FCALCULARSTFONTE_INVERSO
      --42 parametros ( mas pode ser usada pode packages que utilizam a de 38 parÂmetros)
      -- *** Lembrar sincronia entre PRC_MED_CALCULARSTFONTE e PRC_MED_OBTEM_STFONTE ***
      -------------------------------------------------------------------------------------------------------------------
      -------------------------------------------------------------------------------------------------------------------
      -------------------------------------------------------------------------------------------------------------------
      FUNCTION FCALCULARSTFONTE_INVERSO(p_valornotafiscal            IN NUMBER,
                                        p_codprod                    IN NUMBER,
                                        p_condvenda                  IN NUMBER,
                                        p_percvenda                  IN NUMBER,
                                        p_iva                        IN NUMBER,
                                        p_ivafonte                   IN OUT NUMBER,
                                        p_aliqicms1fonte             IN OUT NUMBER,
                                        p_aliqicms2fonte             IN OUT NUMBER,
                                        p_percbaseredstfonte         IN OUT NUMBER,
                                        p_percbaserednrpa            IN NUMBER,
                                        p_percbaseredconsumidor      IN NUMBER,
                                        p_utilizapercbaseredpf_trib  IN VARCHAR2,
                                        p_tipocalcst                 IN VARCHAR2,
                                        p_calcstpf                   IN VARCHAR2,
                                        p_utilizapercbaseredpf       IN VARCHAR2,
                                        p_clientefontest             IN VARCHAR2,
                                        p_calculast                  IN VARCHAR2,
                                        p_ieent                      IN VARCHAR2,
                                        p_tipofj                     IN VARCHAR2,
                                        p_isentoicms                 IN VARCHAR2,
                                        p_consumidorfinal            IN VARCHAR2,
                                        p_utilizaiesimplificada      IN VARCHAR2,
                                        p_tipoempresa                IN VARCHAR2,
                                        p_consideraisentoscomopf     IN VARCHAR2,
                                        p_vlipi                      IN NUMBER,
                                        p_uffilial                   IN VARCHAR2,
                                        p_estent                     IN VARCHAR2,
                                        p_usavalorultentbasest       IN VARCHAR2,
                                        p_valorultent                IN NUMBER,
                                        p_usaivafontediferenciado    IN VARCHAR2,
                                        p_ivafonte_cli               IN NUMBER,
                                        p_AceitaPFContribuinte       IN VARCHAR,
                                        p_ALIQICMS1                  IN NUMBER,
                                        p_ALIQICMS2                  IN NUMBER,
                                        p_contribuinte               IN VARCHAR2,
                                        p_numcasasdecvenda           in NUMBER,
                                        p_baseicst                   OUT NUMBER,
                                        p_mensagem                   OUT VARCHAR2,
                                        P_CUSTONFSEMST               in pcest.custonfsemst%type default 0,
                                        p_usavalorultentbasest2      in pctribut.usavalorultentbasest2%type default 'N',
                                        p_usapmcbasest               in pctribut.usapmcbasest%type default 'N' ,
                                        p_precomaxconsum             in pcprodut.precomaxconsum%type default 0 ,
                                        p_usabaseicmsreduzida        in pctribut.usabaseicmsreduzida%type default 'N',
                                        p_usabcrultent               IN VARCHAR2,
                                        p_basebcrultent              IN NUMBER,
                                        p_stbcrultent                IN NUMBER,
                                        p_CALCSTPAUTAFARMACIAPOPULAR IN VARCHAR2,
                                        p_PAUTAFONTE                 IN NUMBER,
                                        p_FARMACIAPOPULAR            IN VARCHAR2,
                                        p_PARTICIPAFARMACIAPOPULAR   IN VARCHAR2,   
                                        p_usaptabelabasest           IN VARCHAR2,
                                        p_somenteIVATribut           IN VARCHAR2, -- [HIS.05161.2014]
                                        p_usadescsimplesnac          IN VARCHAR2, -- [HIS.05161.2014]
                                        p_simplesnacional            IN VARCHAR2, -- [HIS.05161.2014]
                                        p_percredpvendasimplesnac    IN NUMBER,   -- [HIS.05161.2014]
                                        p_tipomerc                   IN VARCHAR2,
                                        p_usarajusteprecocmed        IN VARCHAR2,
                                        p_percajusteprecocmed        IN NUMBER,
                                        p_medretirarstbnfestadual    IN VARCHAR2,
                                        p_itembonific                IN VARCHAR2,
                                        p_vlfreteoutrasdesp          IN NUMBER,
                                        p_bnfnaocalculaicms          IN VARCHAR2,
                                        p_USAREGSIMPLCARGATRIBSTFONTE  IN VARCHAR2 DEFAULT 'N', -- HIS.03187.2015
                                        p_REGSIMPLCARGATRIBSTFONTE     IN VARCHAR2 DEFAULT 'N', -- HIS.03187.2015
                                        p_PERCREGSIMPLCARGATRIBSTFONTE IN NUMBER   DEFAULT 0,   -- HIS.03187.2015     
                                        p_USAREDUTORCAT49BASESTFONTE   IN VARCHAR2 DEFAULT 'N', -- 5661.146071.2016
                                        p_PERCREDUTORCAT49BASESTFONTE  IN NUMBER   DEFAULT 0,   -- 5661.146071.2016                  
                                        p_USACARGAMINIMADEFERIMSTFONTE IN VARCHAR2 DEFAULT 'N', -- HIS.01277.2017
                                        p_PERCARGAMINIMADEFERIMSTFONTE IN NUMBER   DEFAULT 0,   -- HIS.01277.2017     										
                                        p_USAVLSTMAIORPERCMINPMC       IN VARCHAR2 DEFAULT 'N', -- DDVENDAS-34782
                                        p_PERVLSTMAIORPERCMINPMC       IN NUMBER   DEFAULT 0,   -- DDVENDAS-34782										
                                        p_codfilialfaturamento         IN VARCHAR2,             -- HIS.03371.2017
                                        p_USAREDICMNORMVENDASTFONTE    IN VARCHAR2,             -- MED-1080
                                        p_PERCBASERED                  IN NUMBER,               -- MED-1080
                                        p_percipivenda                 IN NUMBER,
                                        p_usavlultentmediobasest       IN VARCHAR2, 
                                        p_percbasestrj                 IN NUMBER,
                                        p_vlultentmes                  IN NUMBER,
                                        p_valorprodutos                OUT NUMBER,
                                        p_participafuncep              IN  VARCHAR2,
                                        p_codconfigfuncepmed           IN  NUMBER,   
                                        p_aliqicmsfecp                 IN  NUMBER,                                                   
                                        p_vlfecp                       OUT NUMBER,
                                        p_usapmpfbasest                in pctribut.usapmpfbasest%type,
                                        p_pmpf                         IN NUMBER,
                                        po_pmpf                        OUT NUMBER,
                                        p_desvincularFecpSTFuncepICMS  IN VARCHAR2,
                                        p_utilizaCustoContBaseST       in pctribut.utilizarcustocontbasest%type,
                                        p_nFatorAjusteCustoCont        in pctribut.fatorajustecustocont%type,
                                        p_ncustocont                   in pcest.custocont%type										
                                        ) 
      RETURN NUMBER IS
      
        -- Variáveis Locais da Função
        vnpercbasered                  NUMBER;
        vnpercbaseredBaseCred          NUMBER; -- MED-1080
        vnbcst                         NUMBER;
        vnstf1                         NUMBER;
        vnstf2                         NUMBER;
        vnstfonte                      NUMBER;
        vnpbase                        NUMBER;
        vbPessoaFisica                 BOOLEAN;
        vscontribuinte                 PCCLIENT.CONTRIBUINTE%TYPE;
        vnIvaFonte                     NUMBER;
        vbCalculaSTFonte               BOOLEAN;
        vnpvenda                       NUMBER;
        vncustonfsemst                 PCEST.CUSTONFSEMST%TYPE;
        -- Regra Farmácia Popular
        vbRegraFciaPopular             BOOLEAN;
        -- Regra Usar PMC na Base do ST
        vbUsaPmcBaseSt                 BOOLEAN;
        -- PMC de Referência para Ajuste Preço CMED
        vnPmcAjustePrecoCMED           NUMBER;
        -- Valor do Frete e Despesas Acessórias a Somar nas Base de ST
        vnVlFreteOutrasDespBaseSt      NUMBER;
        -- Valor do Frete e Despesas Acessórias a Somar nas Base de ICMS
        vnVlFreteOutrasDespBaseIcms    NUMBER;
        -- Se usa Regra Regime Simplificado pela Carga Tributária Média                   
        vbUsaRegraRegSimplCargaTrib    BOOLEAN;
        vnBcIcmsOperPropriaCargaTribut NUMBER;
        vnVlIcmsOperPropriaCargaTribut NUMBER;
        vnBcEstimatSimplifCargaTribut  NUMBER;
        vnVlEstimatSimplifCargaTribut  NUMBER;
        -- Se usa ST da Última Entrada
        vbUsaRegraStUltimaEntrada      BOOLEAN;
        -- Se Ignorar ST Fonte no TV 10 quando valores zerados na tributação
        vvIgnorarSTFonteTV10Zerado     VARCHAR2(1);  
        -- Regra Exceção ST Fonte Paraná
        vvUsaRegraSTParanaOutrasDesp   VARCHAR2(1);
        -- Base ST Original sem Redução - 5661.146071.2016
        vnBaseStOriginalSemReducao     NUMBER;
        -- HIS.01277.2017
        vnStFonteCargaMinima           NUMBER;
        -- Variáveis Auxiliares da Memória de Calculo
        vnPercMemoriaCalculo           NUMBER;
        vnValorCalculadoMemoriaCalculo NUMBER;
        vvDescOpcaoSelMemoriaCalculo   VARCHAR2(200);
        -- Variáveis para cálculo do ST RJ
        vnBaseStRj                     NUMBER;
        vnValorStRj                    NUMBER;
        vnPercBaseRedRj                NUMBER;
        -- Variáveis para Cálculo do ST Inverso
        vnPercentualValorProdutos      NUMBER;
        vnPercentualBaseSt             NUMBER;
        vnPercentualValorIcmsCompra    NUMBER;
        vnPercentualValorSt            NUMBER;
        vnPercentualValorNotaFiscal    NUMBER;
        vnValordosProdutosPeloStMin    NUMBER;
        -- Regra Usar PMPF na Base do ST
        vbUsaPmPfBaseSt                BOOLEAN;
		vnBaseSTPB					   NUMBER;
        vnStFonteCustoCont			   NUMBER; 
      BEGIN
         
       /********************
        Inicializa Variáveis
        ********************/
        
        -- Valor dos Produtos 
        p_valorprodutos             := 0;
      
        -- Regra Farmácia Popular
        vbRegraFciaPopular          := ( (NVL(p_CALCSTPAUTAFARMACIAPOPULAR,'N') = 'S') and
                                         (NVL(p_FARMACIAPOPULAR,'N') = 'S') and
                                         (NVL(p_PARTICIPAFARMACIAPOPULAR,'N') = 'S') and
                                         (NVL(p_PAUTAFONTE,0) > 0) );

        -- Regra Usar PMC na Base do ST
        vbUsaPmcBaseSt              := ( (NVL(p_PRECOMAXCONSUM,0) > 0) and
                                         (NVL(p_USAPMCBASEST,'N') = 'S') );
  
        -- Rgra Usa ST da Última Entrada (Se não for Consumidor Final)
        vbUsaRegraStUltimaEntrada   := ( (NVL(p_usabcrultent,'N')     = 'S') AND
                                         (NVL(p_consumidorfinal,'N') <> 'S') ); 
  
        -- Regra Regime Simplificado pela Carga Tributária Média -- HIS.03187.2015                                    
        vbUsaRegraRegSimplCargaTrib := ( (NVL(p_USAREGSIMPLCARGATRIBSTFONTE,'N') = 'S') and
                                         (NVL(p_REGSIMPLCARGATRIBSTFONTE,'N')    = 'S') and
                                         (NVL(p_PERCREGSIMPLCARGATRIBSTFONTE,0)  > 0) );

        -- Regra Usar PMPF na Base do ST
        vbUsaPmPfBaseSt              := ( (NVL(p_PMPF,0) > 0) and
                                          (NVL(p_USAPMPFBASEST,'N') = 'S') );
                              
        -- Regra Exceção ST Fonte Paraná para Somar Outras Despesas na Base ICMS com PMC na Base do ST                                      
        BEGIN
          SELECT VALOR
            INTO vvUsaRegraSTParanaOutrasDesp
            FROM PCREGRASEXCECAOMED
           WHERE (CODFILIAL = '99')
             AND (NOME      = 'USAREGRASTPARANAOUTRASDESP');
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vvUsaRegraSTParanaOutrasDesp := 'N';
        END;                     
  
       /***************************
        Inicializa Outras Variáveis
        ***************************/
  
        -- Retorno - SE A LEGISLAÇÃO MUDAR O % DE REDUÇÃO DO CADASTRO - 5661.146071.2016      
  
        -- Outras Variáveis
        vnbcst                      := 0;
        vnstf1                      := 0;
        vnstf2                      := 0;
        vnstfonte                   := 0;
        vbPessoaFisica              := False;
        vnIvaFonte                  := p_IVAFONTE;
        vbCalculaSTFonte            := True;
        --
        vscontribuinte              := p_contribuinte;
        --
        --vnpvenda                    := p_pvenda;
        --
        vnVlFreteOutrasDespBaseSt   := 0;
        vnVlFreteOutrasDespBaseIcms := 0;           
  
        -- Custo NF sem ST
        vncustonfsemst   := p_custonfsemst;   
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
      
       /**********************
        Define se Usa ST Fonte
        **********************/
      
        -- Identificar a incidência de ST Fonte [RDB05]
        vbCalculaSTFonte := (p_CLIENTEFONTEST = 'S')  and
                            ((p_ALIQICMS1FONTE > 0) or (p_ALIQICMS2FONTE > 0));-- and  ((p_ALIQICMS1 = 0) or (p_ALIQICMS2 = 0));
      
        vbCalculaSTFonte := vbCalculaSTFonte and
                            (not ((p_CALCSTPF = 'N') and (vbpessoafisica)));
        
        -- Item Bonificado com Regime Especial pra Retirar ST da Bonificação da NF Estadual
        IF ((NVL(p_itembonific,'N') = 'S') AND
            (NVL(p_medretirarstbnfestadual,'N') = 'S') AND
            (p_uffilial = p_estent)) THEN
          vbCalculaSTFonte            := FALSE;
          vbUsaRegraRegSimplCargaTrib := FALSE; -- HIS.03187.2015
        END IF;
        
        -- Se for Pedido TV10
        IF (pi_nCondVenda = 10) THEN
      
          -- Verifica exceção para ignorar ST Fonte TV 10 quando valores zerados na tibutação
          BEGIN
            SELECT NVL(VALOR,'N')
              INTO vvIgnorarSTFonteTV10Zerado
              FROM PCREGRASEXCECAOMED
             WHERE NOME      = 'IGNORARSTFONTETV10ZERADO'
               AND CODFILIAL = '99';  
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vvIgnorarSTFonteTV10Zerado := 'N';
          END;     
        
          -- Se possuir a regra
          IF vvIgnorarSTFonteTV10Zerado = 'S' THEN
            -- Reinicializa a variável
            vvIgnorarSTFonteTV10Zerado := 'N';
            -- Verifica se os campos estão zerados 
            BEGIN
              SELECT 'S'
                INTO vvIgnorarSTFonteTV10Zerado
                FROM PCTRIBUT 
               WHERE CODST = pio_nCodSt
                 AND NVL(IVATRANSF,0)              <= 0
                 AND NVL(ALIQICMS1TRANSF,0)        <= 0
                 AND NVL(ALIQICMS2TRANSF,0)        <= 0
            	   AND NVL(PAUTATRANSF,0)            <= 0
                 AND NVL(PERCBASEREDSTTRANSF,0)    <= 0
                 AND NVL(IVAFONTETV10,0)           <= 0
                 AND NVL(ALIQICMS1FONTETV10,0)     <= 0
            	   AND NVL(ALIQICMS2FONTETV10,0)     <= 0
                 AND NVL(PERCBASEREDSTFONTETV10,0) <= 0
                 AND NVL(PAUTAFONTETV10,0)         <= 0;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                vvIgnorarSTFonteTV10Zerado := 'N';
            END; 
            
            -- Se os valores para os campos estão zerados, não calcula ST Fonte
            IF (vvIgnorarSTFonteTV10Zerado = 'S') THEN
              vbCalculaSTFonte := FALSE;
            END IF; 
                     
          END IF; -- Fim-Se possui regra para ignorar ST com valores zerados
        END IF; -- Fim-Se Pedido TV10     
        
       /*********************************************************************************************
        *********************************************************************************************
        **                     CALCULAR VALOR DO ST PELA ULTIMA ENTRADA                            **
        *********************************************************************************************
        *********************************************************************************************/
        IF   (vbUsaRegraStUltimaEntrada) AND
             (vbCalculaSTFonte)          THEN -->> HIS.03788.2015 - Somente se for STFONTE
  
          p_mensagem := 'Funcionalidade não habilitada para o ST pela última entrada';
           
       /*********************************************************************************************
        *********************************************************************************************
        **            CALCULAR VALOR DO ST PELA CARGA TRIBUTÁRIA MÉDIA - HIS.03187.2015            **
        *********************************************************************************************
        *********************************************************************************************/
        ELSIF (vbUsaRegraRegSimplCargaTrib) AND
              (vbCalculaSTFonte)            THEN -->> HIS.03371.2017 - Somente se for STFONTE
            
          p_mensagem := 'Funcionalidade não habilitada para o ST pela Carga Tributária Média';
          
       /*********************************************************************************************
        *********************************************************************************************
        **                          CALCULAR VALOR DO ST FONTE [RBD04]                             **
        *********************************************************************************************
        *********************************************************************************************/
        ELSIF (vbCalculaSTFonte) THEN
                        
         /*--------------------------------------------------------------------------------------------
          DEFINIÇÃO DA REDUÇÃO DA BASE DE CÁLCULO
          --------------------------------------*/
        
          vnpercbasered := p_percbaseredstfonte;
        
          -- MED-1080 - Redução da Base Crédito do ST Fonte
          vnpercbaseredBaseCred := p_percbaseredstfonte;
          IF (NVL(p_USAREDICMNORMVENDASTFONTE,'N') = 'S') THEN
            vnpercbaseredBaseCred := p_PERCBASERED; -- MED-1080
          END IF;
        
          ---- Se tipo de empresa do cliente for Normal RPA
          ---- Aplicar %reducao na base de ICMS especifico
          IF (p_tipoempresa = 'NRPA') THEN
            vnpercbasered         := p_percbaserednrpa;
            vnpercbaseredBaseCred := p_percbaserednrpa; -- MED-1080
          END IF;
          ---- Cliente consumidor final utiliza %base red. p/ consumidor final
          IF (p_consumidorfinal = 'S') AND (p_percbaseredconsumidor <> 0) THEN
            vnpercbasered         := p_percbaseredconsumidor;
            vnpercbaseredBaseCred := p_percbaseredconsumidor; -- MED-1080
          END IF;
          ---- Cliente PF que utiliza IE simplificada nao aplica %base red
          IF (p_utilizaiesimplificada = 'S') AND (p_tipofj = 'F') AND
             (p_contribuinte = 'N') THEN
            vnpercbasered         := 0;
            vnpercbaseredBaseCred := 0; -- MED-1080
          END IF;
        
          if vbpessoafisica = true then
            if (p_UTILIZAPERCBASEREDPF = 'N') or
               (p_UTILIZAPERCBASEREDPF_TRIB = 'N') then
              vnPERCBASERED         := 0;
              vnpercbaseredBaseCred := 0; -- MED-1080
            end if;
          end if;
        
          IF (p_isentoicms = 'S') OR (p_condvenda = 7) THEN
            vnpercbasered         := 0;
            vnpercbaseredBaseCred := 0; -- MED-1080
          END IF;
          
          --// MERGE CR -> GU = Farmácia Popular não tem Redução da Base de Cálculo
          if (vbRegraFciaPopular) then
            vnpercbasered         := 0;
            vnpercbaseredBaseCred := 0; -- MED-1080
          end if;    
          
          p_percbaseredstfonte := vnpercbasered;
        
         /*--------------------------------------------------------------------------------------------
          DEFINIÇÃO DO PERCENTUAL DE IVA FONTE
          -----------------------------------*/
        
          -- Definir IVA do ST Fonte [RBD07]
          if p_UsaIVAFonteDiferenciado = 'N' then
            vnIvaFonte := p_IVAFONTE;
          
            --Comentado na 316 por:  //Fernandes 13/09/2011
            --if vnIVAFONTE = 0  and 
            --   not ((nvl(p_PRECOMAXCONSUM,0) > 0) and (NVL(p_USAPMCBASEST,'N') = 'S')) then
            --  p_ALIQICMS1FONTE := 0;
            --  p_ALIQICMS2FONTE := 0;
            --end if;
            --Fim Comentado na 316 por:  //Fernandes 13/09/2011
          elsif p_usaivafontediferenciado = 'S' then
            vnIvaFonte := p_IVAFonte_Cli;
            
          elsif p_usaivafontediferenciado = 'M' then
          
            if p_IVAFONTE > p_IVAFonte_Cli then
              vnIVAFONTE := p_IVAFONTE;
            else
              vnIvaFonte := p_IVAFonte_Cli;
            end if;
            
          end if;
        
          -- [HIS.05161.2014] - Redução Simples Nacional no IVA
          IF (p_somenteIVATribut = 'N') THEN
            IF ((NVL(p_usadescsimplesnac,'N')     = 'N')     AND  -- Somente se na Rotina 132 Não usa desconto do Simples Nacional
                (NVL(p_percredpvendasimplesnac,0) > 0)       AND  -- Somente se tiver % Redução cadastrado na Tributação
                (NVL(p_simplesnacional,'N')       = 'S')     AND  -- Somente se o Cliente participa do Simples Nacional 
                (NVL(p_tipomerc,' ') NOT IN (' ','M','MA'))) THEN -- Somente se não for Medicamento e tiver o Tipo Merc. Preenchido
              vnIvaFonte := vnIvaFonte * (p_percredpvendasimplesnac / 100);
            END IF;          
          END IF;
        
         /*--------------------------------------------------------------------------------------------
          DEFINIÇÃO DA BASE DE CÁLCULO DA ALIQ 01
          --------------------------------------*/
            
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Alíquota de ICMS Compra (Débito)', NULL, p_ALIQICMS1FONTE, NULL);
                                                 
          --------------------------------------------
          -- APLICA REDUÇÃO na Base de Cáculo Aliq. 01
          --------------------------------------------
          
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('Aplicar Redução na Alíquota de Compra (Débito) ?', 'RED_BCSTINV');                
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('1) Sim, aplicar redução', 'RED_BCSTINV', 'SIM');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('2) Não aplicar redução', 'RED_BCSTINV', 'NAO');          
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('RED_BCSTINV', 'NAO'); -->> Default               
          
          -- Se tem Redução na Base do ST
          IF vnpercbasered > 0 THEN
          
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Percentual de Redução', NULL, vnpercbasered, NULL);
                                      
            -- Reduz a Alíquota de ICMS de Compra (Arredonda para 2 casas decimais)
            p_ALIQICMS1FONTE := ROUND((NVL(p_ALIQICMS1FONTE,0) * (NVL(vnpercbasered,0) / 100)),2);
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Alíquota ICMS Compra com Redução [Aliq. Compra x (Redução ' || CHR(247) || ' 100)]', NULL, p_ALIQICMS1FONTE, NULL);
           
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('RED_BCSTINV', 'SIM');                     
            
            
          END IF; -- Fim Condição: APLICA REDUÇÃO na Base de Cáculo Aliq. 01
                  
          ---------------------------------------------        
          -- APLICA O REDUTOR Cat/49 - 5661.146071.2016
          ---------------------------------------------        
          
          -- Se usa Redutor Cat/49
          IF (p_USAREDUTORCAT49BASESTFONTE = 'S') THEN
            IF (NVL(p_PERCREDUTORCAT49BASESTFONTE,0) > 0) THEN
  
              p_mensagem := 'Funcionalidade não habilitada para o ST com Redutor Cat/49';
              
            END IF;
          END IF;
                            
          ---------------------------------------------------------------------------------------------      
          -- Regra Ajuste de Preço CMED para o PMC
          -- (Tributação Marcada para Ajuste de Preço CMED, se tiver PMC e se Não for Farmácia Popular)
          ---------------------------------------------------------------------------------------------      
                  
          -- Se Utilizar Legislação Cat/35 (Ajuste Preço CMED)
          IF (NVL(p_usarajusteprecocmed,'N') = 'S') AND
             (NVL(p_PRECOMAXCONSUM,0) > 0) AND
             (NOT vbRegraFciaPopular) THEN
                       
            p_mensagem := 'Funcionalidade não habilitada para o ST com Legislação Cat/35 (Ajuste Preço CMED)';
                                         
          -----------------------------------------------
          -- Preço Tabela na Base do ST
          -----------------------------------------------
          ELSIF (NVL(p_usaptabelabasest,'N') = 'S') THEN
  
            p_mensagem := 'Funcionalidade não habilitada para o ST com Preço de Tabela na Base do ST';
                                                                                                          
          -----------------------------------------------
          -- Demais Casos (FARMACIA POPULAR, PMC, MVA ...
          -----------------------------------------------
          ELSE
                  
           /*--------------------------------------------------------------------------------------------
            DEFINIÇÃO DO VALOR DO ICMS INTERNO
            ---------------------------------*/
        
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('Opção de Cálculo Inverso do ST', 'INVERSO_ST');                
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('1) Cálculo inverso de ST com Pauta', 'INVERSO_ST', 'PAUTA_INVERSOST');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('2) Cálculo inverso de ST com Valor da Ultima Entrada RJ', 'INVERSO_ST', 'VLENTRJ_INVERSOST');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('3) Cálculo inverso de ST com PMC', 'INVERSO_ST', 'PMC_INVERSOST');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('4) Cálculo inverso de ST pela Média dos Valores das Entradas (MG)', 'INVERSO_ST', 'MEDIAMG_INVERSOST');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('4) Cálculo inverso de ST pelo MVA', 'INVERSO_ST', 'MVA_INVERSOST');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('5) Não Aplicar ST inverso (funcionalidade não habilitada)', 'INVERSO_ST', 'NAO_INVERSOST');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('6) Cálculo inverso de ST com PMPF', 'INVERSO_ST', 'PMPF_INVERSOST');          
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('INVERSO_ST', 'NAO_INVERSOST'); -->> Default               
        
            -- *** CALCULO INVERSO COM PAUTA SEM MVA ***
            -- FARMACIA POPULAR
            -- PMC
            -- PMPF
            if (vbRegraFciaPopular) or
               (vbUsaPmcBaseSt)     or
               (vbUsaPmPfBaseSt)    then
            
              IF    (vbRegraFciaPopular) THEN
              
                -- Pauta = Pauta Fonte Tributação
                p_pautafonteaplicado := NVL(p_PAUTAFONTE,0);
                
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Pauta (Pauta Fonte ST)', NULL, NULL, p_pautafonteaplicado);
                
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('INVERSO_ST', 'PAUTA_INVERSOST');
                
              ELSIF (vbUsaPmcBaseSt)     THEN 
  
                -- Pauta = PMC
                p_pautafonteaplicado := NVL(P_PRECOMAXCONSUM,0);
              
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Pauta (PMC)', NULL, NULL, p_pautafonteaplicado);
              
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Aliq. Compra', NULL, p_ALIQICMS1FONTE, NULL);
              
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('INVERSO_ST', 'PMC_INVERSOST');
 
 
               ELSIF (vbUsaPmPfBaseSt)     THEN 
               
                po_pmpf := NVL(P_PMPF,0);                
  
                -- Pauta = PMPF
                p_pautafonteaplicado := NVL(P_PMPF,0);
              
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Pauta (PMPF)', NULL, NULL, p_pautafonteaplicado);
              
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Aliq. Compra', NULL, p_ALIQICMS1FONTE, NULL);
              
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('INVERSO_ST', 'PMPF_INVERSOST');
              
             
              END IF;
                                                                    
              -- Valor Icms Compra - Débito
              vnSTF1 := NVL(p_pautafonteaplicado,0) * (NVL(p_ALIQICMS1FONTE,0)/100);
              p_baseicst := NVL(p_pautafonteaplicado,0); -- MED-1930
              IF (NVL(vnpercbasered,0) > 0) THEN
                -- Compensar a Alíquota que foi reduzida
                p_baseicst := (NVL(p_baseicst,0) * (NVL(vnpercbasered,0) / 100)); 
              END IF;
              
              
              
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('>', 'Valor Icms Compra (Débito) = [Pauta x (Aliq. Compra ' || CHR(247) || ' 100)]',  NULL, NULL, vnSTF1);
                             
            -- *** CALCULO INVERSO COM PAUTA MAS COM MVA ***
            -- ST RJ
            elsif ((NVL(p_usavalorultentbasest,'N') = 'S') AND (NVL(p_percbasestrj,0) > 0)) then
  
              -- Pauta = Valor da Ultima Entrada
              p_pautafonteaplicado := NVL(p_valorultent,0);
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Pauta (Valor Ultima Entrada)', NULL, NULL, p_pautafonteaplicado);
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Percentual de MVA', NULL, vnIVAFONTE, NULL);
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Aliq. Compra', NULL, p_ALIQICMS1FONTE, NULL);
  
              -- Valor Icms Compra - Débito
              vnSTF1 := (NVL(p_pautafonteaplicado,0) * (1 + (NVL(vnIVAFONTE,0) / 100))) * (NVL(p_ALIQICMS1FONTE,0)/100);
              p_baseicst := (NVL(p_pautafonteaplicado,0) * (1 + (NVL(vnIVAFONTE,0) / 100))); -- MED-1930
              IF (NVL(vnpercbasered,0) > 0) THEN
                -- Compensar a Alíquota que foi reduzida
                p_baseicst := (NVL(p_baseicst,0) * (NVL(vnpercbasered,0) / 100)); 
              END IF;
              
              
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('>', 'Valor Icms Compra (Débito) = [(Pauta x (1 + (MVA ' || CHR(247) || ' 100))) x (Aliq. Compra ' || CHR(247) || ' 100)]', NULL, NULL, vnSTF1);
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('INVERSO_ST', 'VLENTRJ_INVERSOST');    
  
            -- ST MG (Pelo Valor Médio das Ultimas Entradas)
            elsif (NVL(p_usavlultentmediobasest,'N') = 'S') then
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Vl.Médio Entradas', NULL, NULL, p_vlultentmes);
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Percentual de MVA', NULL, vnIVAFONTE, NULL);
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Aliq. Compra', NULL, p_ALIQICMS1FONTE, NULL);
  
              -- Valor Icms Compra - Débito
              vnSTF1 := (NVL(p_vlultentmes,0) * (1 + (NVL(vnIVAFONTE,0) / 100))) * (NVL(p_ALIQICMS1FONTE,0)/100);
              p_baseicst := (NVL(p_vlultentmes,0) * (1 + (NVL(vnIVAFONTE,0) / 100))); -- MED-1930
              IF (NVL(vnpercbasered,0) > 0) THEN
                -- Compensar a Alíquota que foi reduzida
                p_baseicst := (NVL(p_baseicst,0) * (NVL(vnpercbasered,0) / 100)); 
              END IF;
              
              
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('>', 'Valor Icms Compra (Débito) = [(Vl.Médio Entradas x (1 + (MVA ' || CHR(247) || ' 100))) x (Aliq. Compra ' || CHR(247) || ' 100)]', NULL, NULL, vnSTF1);
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('INVERSO_ST', 'MEDIAMG_INVERSOST');    
               
            -- Demais casos: COM IVA
            else
            
              -- *************************************************************************************************
              -- *** O CÁLCULO SEM PAUTA E COM MVA SERÁ FEITO AO FINAL DESTA FUNÇÃO COM UMA FÓRMULA ESPECÍFICA ***
              -- *************************************************************************************************
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('INVERSO_ST', 'MVA_INVERSOST');    
      
            end if;
            
          END IF;
                            
          -- Valor Aliq. 01 --
          --------------------
          
         /*--------------------------------------------------------------------------------------------
          DEFINIÇÃO DA BASE DE CALCULO DA ALIQ 02
          --------------------------------------*/
                    
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Alíquota de ICMS Venda (Crédito)', NULL, p_ALIQICMS2FONTE, NULL);
                    
          ---------------------------------------------
          -- Se usa Base ICMS Reduzida no Cálculo do ST
          ---------------------------------------------
          
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('Aplicar Redução na Base de ICMS (Crédito) ?', 'RED_BCICMINV');                
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('1) Sim, reduzir a base usando o Percentual Redução do ST Fonte', 'RED_BCICMINV', 'SIM_REDFONTE');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('2) Sim, reduzir a base usando o Percentual Redução do ICMS da Venda', 'RED_BCICMINV', 'SIM_REDVENDA');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('3) Não reduzir a base', 'RED_BCICMINV', 'NAO');          
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('RED_BCICMINV', 'NAO'); -->> Default               
          
                                                                                                                                             -- Inicio: Memória de Cálculo
                                                                                                                                             -- Se usa Base ICMS Reduzida
                                                                                                                                             IF (p_usabaseicmsreduzida = 'S') THEN
            
                                                                                                                                             -- MED-1080 - Redução da Base Crédito do ST Fonte
                                                                                                                                             IF (NVL(p_USAREDICMNORMVENDASTFONTE,'N') = 'S') THEN
              
                                                                                                                                             IF vnpercbaseredBaseCred > 0 THEN
               
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('RED_BCICMINV', 'SIM_REDVENDA');                                               
                                                                                      
                                                                                                                                             END IF;
              
                                                                                                                                             ELSE
                        
                                                                                                                                             IF vnpercbasered > 0 THEN
              
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('RED_BCICMINV', 'SIM_REDFONTE');                                 
                                                                                      
                                                                                                                                             END IF;
              
                                                                                                                                             END IF;
                                                                                                                                             END IF;
                                                                                                                                             -- Fim: Memória de Cálculo
            
          -- Se Item Bonificado e a Bonificação não calcular ICMS
          IF ((p_itembonific IN ('S','F')) and -- DDMEDICA-198 - Incluir F
              (p_bnfnaocalculaicms = 'S')) THEN
  
            p_mensagem := 'Funcionalidade não habilitada para o ST com Item Bonificado';
            --p_ALIQICMS2FONTE := 0;
  
          END IF;
                                    
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Percentual de Redução', NULL, vnpercbaseredBaseCred, NULL);
                                    
          -- Se usa Base ICMS Reduzida
          IF (p_usabaseicmsreduzida = 'S') THEN
          
            -- Reduz a Alíquota de ICMS de Compra (Arredonda para 2 casas decimais)
            IF vnpercbaseredBaseCred > 0 THEN
    	
              p_ALIQICMS2FONTE := ROUND((NVL(p_ALIQICMS2FONTE,0) * (NVL(vnpercbaseredBaseCred,0) / 100)),2);
      
                                                                                                                                               -- Memória de Cálculo          
                                                                                                                                               P_INSERIR_MEMORIA_CALCULO('=', 'Alíquota ICMS Venda com Redução [Aliq. Venda x (Redução ' || CHR(247) || ' 100)]', NULL, p_ALIQICMS2FONTE, NULL);
            END IF;																																		   
  
          END IF;
            
          -- Valor Aliq. 02 --
          --------------------
                                      
         /*--------------------------------------------------------------------------------------------
          CALCULO DO ST FONTE
          ------------------*/
                       
          --------------------------------------------------------
          -- CARGA MÍNIMA DEFERIMENTO ST FONTE - HIS.01277.2017 --
          --------------------------------------------------------
          
          -- Se usa Carga Mínima de ST Fonte
          IF (p_USACARGAMINIMADEFERIMSTFONTE = 'S') THEN
                         
            p_mensagem := 'Funcionalidade não habilitada para o ST com Carga Mínima de Deferimento do ST Fonte';
                                                        
          END IF; -- FIM: CARGA MÍNIMA DEFERIMENTO ST FONTE - HIS.01277.2017
  
          IF (p_USAVLSTMAIORPERCMINPMC = 'S') THEN
                         
            p_mensagem := 'Funcionalidade não habilitada para o Valor de ST Maior que Percentual Mínimo sobre PMC';
                                                        
          END IF; -- FIM: CARGA MÍNIMA DEFERIMENTO ST FONTE - HIS.01277.2017  
  
         /**********************************************************************************************
           CÁLCULO DO VALOR DOS PRODUTOS USANDO PAUTA (FARMACIA POPULAR, PMC, VALOR ULTIMA ENTRADA ...)
          **********************************************************************************************/
          -- *** CALCULO INVERSO COM PAUTA SEM MVA *****************************************************
          -- FARMACIA POPULAR
          -- PMC
          -- PMPF
          IF (vbRegraFciaPopular) OR
             (vbUsaPmcBaseSt)     OR
             (vbUsaPmPfBaseSt)    OR
          -- *** CALCULO INVERSO COM PAUTA MAS COM MVA ***
          -- ST RJ
             ((NVL(p_usavalorultentbasest,'N') = 'S') AND (NVL(p_percbasestrj,0) > 0)) THEN
             
            -- Requer Alíquota de Venda para não dar erro de divisão por zero
            IF (NVL(p_ALIQICMS2FONTE,0) > 0) THEN
             
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('>', 'Valor Nota Fiscal', NULL, NULL, p_valornotafiscal);
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('>', 'Valor ICMS Compra', NULL, NULL, vnSTF1);
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('>', 'Aliq. ICMS Venda', NULL, NULL, p_ALIQICMS2FONTE);
  
              -- Cálculo do Valor dos Produtos sem Impostos
              p_valorprodutos := (NVL(p_valornotafiscal,0) - NVL(vnSTF1,0)) / ( 1 - (NVL(p_ALIQICMS2FONTE,0) / 100));
              p_valorprodutos := round(p_valorprodutos, p_numcasasdecvenda);   
               
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('#', 'Valor dos Produtos = [(Valor Nota Fiscal - Valor Icms Compra) ' || CHR(247) || ' ( 1 - (Aliq. ICMS Venda ' || CHR(247) || ' 100))]', p_valorprodutos, NULL, NULL);
                            
            ELSE
             
              p_mensagem := 'Funcionalidade não habilitada para o ST sem Alíquota de Venda (Crédito)';
             
            END IF;
          
           /*************
            ST DE RETORNO
            *************/
            vnstfonte :=  (NVL(p_valornotafiscal,0) - NVL(p_valorprodutos,0)) ;
    
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('#', 'Valor do ST = (Valor NF - Valor Produtos)', NULL, NULL, vnstfonte);
            
            --Calcular ST - Truncar com 2 casas decimais
            IF p_tipocalcst = 'T2' THEN
              vnstfonte := trunc((vnstfonte) * 100) / 100;
            ELSIF p_tipocalcst = 'A2' THEN
              vnstfonte := round((vnstfonte) * 100) / 100;
            ELSIF p_tipocalcst = 'PV' THEN
              vnSTFONTE := round(vnSTFONTE, p_numcasasdecvenda);       
            END IF;
          
          -- *** CALCULO ST MG *************************************************************************
          ELSIF (NVL(p_usavlultentmediobasest,'N') = 'S') THEN
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Vl.Médio Entradas', NULL, NULL, p_vlultentmes);
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Aliq. Venda', NULL, p_ALIQICMS2FONTE, NULL);
  
            -- Valor Icms Venda - Crédito
            vnSTF2 := (NVL(p_vlultentmes,0) * (NVL(p_ALIQICMS2FONTE,0)/100));
            
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('>', 'Valor Icms Venda (Crédito) = (Vl.Médio Entradas x * (Aliq. Venda ' || CHR(247) || ' 100)', NULL, NULL, vnSTF2);
  
           /*************
            ST DE RETORNO
            *************/
            vnstfonte :=  (NVL(vnSTF1,0)- NVL(vnSTF2,0)) ;
                      
            --Calcular ST - Truncar com 2 casas decimais
            IF p_tipocalcst = 'T2' THEN
              vnstfonte := trunc((vnstfonte) * 100) / 100;
            ELSIF p_tipocalcst = 'A2' THEN
              vnstfonte := round((vnstfonte) * 100) / 100;
            ELSIF p_tipocalcst = 'PV' THEN
              vnstfonte := round(vnstfonte, p_numcasasdecvenda);       
            END IF;          
            
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('>', 'Valor do ST MG = (Valor Icms Compra - Valor Icms Venda)', NULL, NULL, vnstfonte);
                                                                                                                               
            -- Calcula o Valor dos Produtos pelo ST MG
            p_valorprodutos := NVL(p_valornotafiscal,0) - NVL(vnstfonte,0);
            p_valorprodutos := round(p_valorprodutos, p_numcasasdecvenda);   
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('>', 'Valor Nota Fiscal', NULL, NULL, p_valornotafiscal);
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('#', 'Valor dos Produtos pelo ST MG = (Valor NF - Valor ST MG)', NULL, NULL, p_valorprodutos);
  
             
          -- *** CALCULO INVERSO COM MVA SEM PAUTA *****************************************************
          ELSE
          
            -- Valor dos Produtos em Percentual
            vnPercentualValorProdutos := 100;
          
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Valor dos Produtos em Percentual', vnPercentualValorProdutos, NULL, NULL);
  
            -- Inicializa a Base do ST em Percentual
            vnPercentualBaseSt := vnPercentualValorProdutos;
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Base do ST em Percentual = Valor dos Produtos em Percentual', vnPercentualValorProdutos, NULL, NULL);
  
            -- Soma o IVA na Base do ST em Percentual
            vnPercentualBaseSt := vnPercentualBaseSt + NVL(vnIVAFONTE,0);
  
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('+', 'Acresce o MVA em Percentual', vnPercentualBaseSt , NVL(vnIVAFONTE,0) , NULL, TRUE);
          
            -- Cálculo do Icms de Compra em Percentual
            vnPercentualValorIcmsCompra := NVL(vnPercentualBaseSt,0) * (p_ALIQICMS1FONTE / 100);
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Valor do Icms Compra em Percentual = [Base do ST em Percentual x (Aliq. ICMS Compra ' || CHR(247) || ' 100)]', NULL, NULL, vnPercentualValorIcmsCompra);
          
            -- Cálculo do Valor do ST em Percentual
            vnPercentualValorSt := (NVL(vnPercentualValorIcmsCompra,0) - NVL(p_ALIQICMS2FONTE,0));
            
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Valor do ST em Percentual = (Valor do Icms Compra em Percentual - Aliq. ICMS Venda)', NULL, NULL, vnPercentualValorSt);
                                      
            -- Cálculo do Valor da Nota Fiscal em Percentual
            vnPercentualValorNotaFiscal := NVL(vnPercentualValorProdutos,0) + NVL(vnPercentualValorSt,0);                                      
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('>', 'Valor Nota Fiscal em Percentual = (Valor dos Produtos em Percentual + Valor do ST em Percentual)', NULL, NULL, vnPercentualValorNotaFiscal);
          
            -- Cálculo do Valor dos Produtos sem Impostos
            p_valorprodutos := (NVL(p_valornotafiscal,0) / (NVL(vnPercentualValorNotaFiscal,0) / 100));
            p_valorprodutos := round(p_valorprodutos, p_numcasasdecvenda);   
             
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Valor Nota Fiscal em R$', NULL, NULL, p_valornotafiscal);
             
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('#', 'Valor dos Produtos = [Valor NF em R$ ' || CHR(247) || ' (Valor NF em Percentual ' || CHR(247) || ' 100)]', NULL, NULL, p_valorprodutos);
          
           /*************
            ST DE RETORNO
            *************/
            vnstfonte :=  (NVL(p_valornotafiscal,0) - NVL(p_valorprodutos,0)) ;
  
            -- Retorno da Base do ST -- MED-1930    
            p_baseicst := (NVL(p_valorprodutos,0) * (1 + (NVL(vnIVAFONTE,0) / 100)));
            IF (NVL(vnpercbasered,0) > 0) THEN
              -- Compensar a Alíquota que foi reduzida
              p_baseicst := (NVL(p_baseicst,0) * (NVL(vnpercbasered,0) / 100)); 
            END IF;
    
    
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('#', 'Valor do ST = (Valor NF - Valor Produtos)', NULL, NULL, vnstfonte);
            
            --Calcular ST - Truncar com 2 casas decimais
            IF p_tipocalcst = 'T2' THEN
              vnstfonte := trunc((vnstfonte) * 100) / 100;
            ELSIF p_tipocalcst = 'A2' THEN
              vnstfonte := round((vnstfonte) * 100) / 100;
            ELSIF p_tipocalcst = 'PV' THEN
              vnSTFONTE := round(vnSTFONTE, p_numcasasdecvenda);       
            END IF;
          
          END IF;              
                  
  
          -------------------------------------------------------------------------
          -- ST FECP - MED-1930
          -------------------------------------------------------------------------               
  
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('Abater FECP do Valor ST Total ?', 'VL_FECP');                
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('1) Sim', 'VL_STRJINV', 'SIM_FECP');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('2) Não', 'VL_STRJINV', 'NAO_FECP');   
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('VL_FECP', 'NAO_FECP'); -->> Default               
          
          IF ((NVL(p_participafuncep,'S')  = 'S') OR 
              ((NVL(p_desvincularFecpStFuncepICMS,'N')  = 'S')
                AND (NVL(p_participafuncep,'S')  = 'N'))) AND															 
             (NVL(p_codconfigfuncepmed,0) >  0 ) AND
             (NVL(p_aliqicmsfecp,0)       >  0 ) THEN
            -- Calcula o ST FECP
            p_vlfecp := NVL(p_baseicst,0) * (NVL(p_aliqicmsfecp,0) / 100);
            IF (NVL(p_vlfecp,0) < 0) THEN
              p_vlfecp := 0;
            END IF;
            -- Arredondamento ST
            IF p_tipocalcst = 'T2' THEN
              p_vlfecp := trunc((p_vlfecp) * 100) / 100;
            ELSIF p_tipocalcst = 'A2' THEN
              p_vlfecp := round((p_vlfecp) * 100) / 100;
            ELSIF p_tipocalcst = 'PV' THEN
              p_vlfecp := round(p_vlfecp, p_numcasasdecvenda);       
            END IF;          
            -- Abate o FECP do ST
            vnSTFONTE := NVL(vnSTFONTE,0) - NVL(p_vlfecp,0); 
            IF (NVL(vnSTFONTE,0) < 0) THEN
              vnSTFONTE := 0;
            END IF;          
            
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('VL_FECP', 'SIM_FECP');
                                                                                                                                             
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('#', 'Abater o Valor do FECP do ST Total', NULL, NULL, p_vlfecp);
                                                                                                                                                       
          ELSE        
            p_vlfecp := 0;
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('VL_FECP', 'NAO_FECP');
            
          END IF;
  
                  
          -------------------------------------------------------------------------
          -- PERCENTUAL BASE RJ - Priorização do Maior entre o Mínimo e o Calculado
          -------------------------------------------------------------------------
          
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('Calcular ST pelo Percentual Mínimo RJ ?', 'VL_STRJINV');                
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('1) Sim', 'VL_STRJINV', 'SIM_STRJ');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('2) Não', 'VL_STRJINV', 'NAO_STRJ');   
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('VL_STRJINV', 'NAO_STRJ'); -->> Default               
          
          -- Se Calcula ST MÍNIMO RJ
          IF (NVL(p_usavalorultentbasest,'N') = 'S') AND
             (NVL(p_percbasestrj,0) > 0)             THEN
  
            -- Base ST Mínimo Rj pelo Valor da Última Entrada
            vnBaseStRj := NVL(p_valorultent,0);
  
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Valor Inicial da Base ST Mínimo RJ', vnBaseStRj);
                                                                          
            -- Agrega o MVA na Base do ST Mínimo Rj
            vnBaseStRj := (vnBaseStRj * (1 + (vnIVAFONTE / 100)));
                                      
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('+', 'MVA', vnBaseStRj, vnIVAFONTE, vnValorCalculadoMemoriaCalculo);                                      
          
            -- Redução ST Mínimo Rj
            vnPercBaseRedRj := NVL(vnpercbasered,0); 
            IF (NVL(vnPercBaseRedRj,0) = 0) THEN
              vnPercBaseRedRj := 100;
            END IF;
            
                                                                                                                                             -- Variáveis Auxiliares da Memória de Calculo
                                                                                                                                             vnPercMemoriaCalculo           := (100 - vnPercBaseRedRj);
                                                                                                                                             vnValorCalculadoMemoriaCalculo := (vnBaseStRj * (vnPercMemoriaCalculo / 100));
            
            -- Aplica Redução na Base do ST Rj
            vnBaseStRj := vnBaseStRj * (vnPercBaseRedRj / 100);
          
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('-', 'Redução de ' || vnPercBaseRedRj || '% na Base ST Mínimo', vnBaseStRj, vnPercMemoriaCalculo, vnValorCalculadoMemoriaCalculo);
          
            -- Calcula o Valor do ST RJ  
            vnValorStRj := vnBaseStRj * (NVL(p_percbasestrj,0) / 100);
            
            --Calcular ST - Truncar com 2 casas decimais
            IF p_tipocalcst = 'T2' THEN
              vnValorStRj := trunc((vnValorStRj) * 100) / 100;
            ELSIF p_tipocalcst = 'A2' THEN
              vnValorStRj := round((vnValorStRj) * 100) / 100;
            ELSIF p_tipocalcst = 'PV' THEN
              vnValorStRj := round(vnValorStRj, p_numcasasdecvenda);       
            END IF;          
            
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('>', 'Valor Mínimo ST RJ', NULL, p_percbasestrj, vnValorStRj);
                                                                               
                                                  
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('VL_STRJ', 'MIN_STRJ'); 
                                        
            -- Calcula o Valor dos Produtos pelo Mínimo
            vnValordosProdutosPeloStMin := NVL(p_valornotafiscal,0) - NVL(vnValorStRj,0);
            vnValordosProdutosPeloStMin := round(vnValordosProdutosPeloStMin, p_numcasasdecvenda);   
  
                                      
            -- Verifica o Maior ST para definir qual aplicar a Inversão
            IF (NVL(vnValorStRj,0) > NVL(vnstfonte,0)) THEN
  
             /*****************************************
              ALTERA ST DE RETORNO E VALOR DOS PRODUTOS
              *****************************************/
              vnstfonte := NVL(vnValorStRj,0);            
              p_valorprodutos := NVL(vnValordosProdutosPeloStMin,0);
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('#', 'Valor dos Produtos pelo ST Mínimo = (Valor NF - Valor ST Mínimo)', NULL, NULL, vnValordosProdutosPeloStMin);
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('#', 'Substituição do Valor dos Produtos pelo calculado pelo ST Mínimo', NULL, NULL, p_valorprodutos);
              
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('VL_STRJINV', 'SIM_STRJ');
              
            END IF;
  
          END IF; -- Fim Condição: ST MÍNIMO RJ
          
        END IF; -- FIM CONDIÇÃO CALCULA VALOR DO ST
		IF (NVL(p_utilizaCustoContBaseST,'N') = 'S') AND  (NVL(p_nFatorAjusteCustoCont,0) > 0) THEN
           vnbcst := (NVL(vnPVENDA,0) +  NVL(p_vlfreteoutrasdesp,0));
           
      	   P_INSERIR_MEMORIA_CALCULO('=', 'Substituição da Base do ST conforme ST pvenda + Despesas PB', NULL, NULL, vnbcst);
           vnBaseSTPB := ((NVL(p_ncustocont,0)/(1-(p_nFatorAjusteCustoCont/100))) +  NVL(p_vlfreteoutrasdesp,0));
		   P_INSERIR_MEMORIA_CALCULO('#', 'Substituição da Base do ST conforme ST Custo Cont + Fator + Despesas PB', NULL, NULL, round(vnBaseSTPB,p_numcasasdecvenda)); 

           vnstfonte  := vnbcst * (p_aliqicms1fonte/100);

           vnStFonteCustoCont := vnBaseSTPB * (p_aliqicms1fonte/100);

          IF (vnstfonte < vnStFonteCustoCont) THEN
              vnstfonte := vnStFonteCustoCont;
              vnbcst :=   vnBaseSTPB;
          END IF;
                      --Calcular ST - Truncar com 2 casas decimais
          IF p_tipocalcst = 'T2' THEN
            vnstfonte := trunc((vnstfonte) * 100) / 100;
          ELSIF p_tipocalcst = 'A2' THEN
            vnstfonte := round((vnstfonte) * 100) / 100;
          ELSIF p_tipocalcst = 'PV' THEN
            vnSTFONTE := round(vnSTFONTE, p_numcasasdecvenda);
          END IF;
          P_INSERIR_MEMORIA_CALCULO('#', 'Substituição da Base do ST conforme Regime Especial PB', NULL, NULL, round(vnbcst,p_numcasasdecvenda));   
          P_INSERIR_MEMORIA_CALCULO('#', 'Substituição conforme Regime Especial PB', NULL, NULL, vnstfonte);
        END IF;              
       /*--------------------------------------------------------------------------------------------
        Atualização de Retornos adicionais
        ---------------------------------*/
              
       /*--------------------------------------------------------------------------------------------
        Retornos Base e Valor do ST
        --------------------------*/
        RETURN vnstfonte;
        
      EXCEPTION
        WHEN OTHERS THEN
          p_mensagem := 'Erro ao calcular STfonte: ' || SQLCODE || '-' ||
                        SQLERRM;
          RETURN 0;
      END FCALCULARSTFONTE_INVERSO;  
  
      -------------------------------------------------------------------------------------------------------------------
      -------------------------------------------------------------------------------------------------------------------
      -------------------------------------------------------------------------------------------------------------------
      -- FUNCTION PCALCULARFUNCEP
      -- Calcular ST do Funcep
      -------------------------------------------------------------------------------------------------------------------
      -------------------------------------------------------------------------------------------------------------------
      -------------------------------------------------------------------------------------------------------------------
      PROCEDURE PCALCULARFUNCEP(p_codconfigfuncepmed           IN  NUMBER,
                                p_bcst                         IN  NUMBER,
                                p_pvenda                       IN  NUMBER,
                                p_observacaostfonte            IN OUT VARCHAR2, 
                                p_aliqicmsfecp                 IN  NUMBER, -- HIS.04200.2017
                                p_VLBASEFCPICMS                OUT NUMBER, -- HIS.04200.2017
                                p_VLBASEFCPST                  OUT NUMBER, -- HIS.04200.2017
                                p_VLBCFCPSTRET                 OUT NUMBER, -- HIS.04200.2017
                                p_PERFCPSTRET                  OUT NUMBER, -- HIS.04200.2017
                                p_PERFCPSN                     OUT NUMBER, -- HIS.04200.2017
                                p_VLFECP                       OUT NUMBER, -- HIS.04200.2017
                                p_VLACRESCIMOFUNCEP            OUT NUMBER, -- HIS.04200.2017
                                p_VLCREDFCPICMSSN              OUT NUMBER,
                                p_mensagem                     OUT VARCHAR2,
                                p_vlfreteoutrasdespbaseicms    IN  NUMBER, -- MED-2346
                                p_percbaseredicmsfecp          IN  NUMBER) -- MED-2346
      IS
             
        vnPercBaseRedIcmsNormal PCPEDI.PERCBASERED%TYPE; -- MED-2346
        vnBaseIcmsNormalFecp    NUMBER; -- MED-2346
        vnValorIcmsNormalFecp   NUMBER; -- MED-2346
             
      BEGIN
      
       /********************
        Inicializa Variáveis
        ********************/
      
                                                                                                                         -- Continuação da Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',St.Funcep';
                        
       /*--------------------------------------------------------------------------------------------
        CÁLCULO DO ST FUNCEP
        -- * QUANDO NÃO TEM ST, ONDE CADASTRA o Percentual do Fundo de Combate à Pobreza (pFCP ) 
        -------------------*/
        IF (NVL(p_codconfigfuncepmed,0) > 0) THEN
          -- Fundo de Combate à Pobreza
          p_vlbasefcpicms      := 0; -- MED-656 - Será Calculado no Faturamento -- Valor da Base de Cálculo do FCP [vBCFCP]
          -->> p_peracrescimofuncep --> SERÁ USADO PARA GRAVAR O CAMPO Percentual do FCP retido por Substituição Tributária [pFCPST]
          p_vlacrescimofuncep  := 0; -- MED-656 - Será Calculado no Faturamento -- SERÁ USADO PARA GRAVAR O CAMPO Valor do Fundo de Combate à Pobreza (FCP) [vFCP]
    
          -- Simples Nacional
          p_perfcpsn           := 0;                                                              -- ??? Alíquota aplicável de cálculo do crédito (SIMPLES NACIONAL). [pCredSN]
          p_vlcredfcpicmssn    := 0;                                                              -- ??? Valor crédito do ICMS que pode ser aproveitado nos termos do art. 23 da LC 123 (SIMPLES NACIONAL) [vCredICMSSN]
    
         -- Retido anteriormente por ST 
          p_vlbcfcpstret       := 0;                                                              -- Valor da Base de Cálculo do FCP retido anteriormente [vBCFCPSTRet]
          p_perfcpstret        := 0;                                                              -- Percentual do FCP retido anteriormente por Substituição Tributária [pFCPSTRet]
          p_vlfcpstret         := 0;                                                              -- Valor do Fundo de Combate à Pobreza (FCP) [vFCP]             -- Valor Total do FCP retido anteriormente por Substituição Tributária [vFCPSTRet]
    
          -->> p_aliqicmsfecp -->> Percentual do FCP retido por Substituição Tributária [pFCPST]
    
          -- Retido por Substituição Tributária (CUIDADO QUE O NOME DAS COLUNAS NÃO CORRESPONDE AO NOME DAS TAGS POR REAPROVEITAMENTO DO OERACRESCIMOFUNCEP)
          -- Valor da Base de Cálculo do FCP retido por Substituição Tributária [vBCFCPST]        
          IF    (p_codconfigfuncepmed = 1) THEN
  
            p_vlbasefcpst       := p_bcst;                                                              
                                                                                                                         -- Observação ST Fonte
            -- Valor do FCP retido por Substituição Tributária [vFCPST]     
            p_vlfecp            := (NVL(p_vlbasefcpst,0) * (NVL(p_aliqicmsfecp,0) / 100));       
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',1-BaseSt';
          ELSIF (p_codconfigfuncepmed = 2) THEN
      
            p_vlbasefcpst       := p_pvenda;                                                              
      
            -- Valor do FCP retido por Substituição Tributária [vFCPST]     
            p_vlfecp            := (NVL(p_vlbasefcpst,0) * (NVL(p_aliqicmsfecp,0) / 100));       
                 
          -- MED-2346                                                                                                               -- Observação ST Fonte
          ELSIF (p_codconfigfuncepmed = 3) THEN
      
            p_vlbasefcpst         := p_bcst;                                                              
            
            -- Redução do ICMS Normal - MED-2346
            vnPercBaseRedIcmsNormal := NVL(p_percbaseredicmsfecp,0);
            IF (NVL(vnPercBaseRedIcmsNormal,0) = 0) THEN
              vnPercBaseRedIcmsNormal := 100;
          END IF;
            
            -- Base Icms Normal FECP - MED-2346
            vnBaseIcmsNormalFecp  := (NVL(p_pvenda,0) + NVL(p_vlfreteoutrasdespbaseicms,0));
            vnBaseIcmsNormalFecp  := (NVL(vnBaseIcmsNormalFecp,0) * (NVL(vnPercBaseRedIcmsNormal,0) / 100));
            
            -- Valor ICMS Normal FECP - MED-2346
            vnValorIcmsNormalFecp := (NVL(vnBaseIcmsNormalFecp,0) * (NVL(p_peracrescimofuncep,0) / 100));
            
            -- Valor do FCP retido por Substituição Tributária [vFCPST]     
            p_vlfecp              := (NVL(p_vlbasefcpst,0) * (NVL(p_aliqicmsfecp,0) / 100));       
          
            -- Retira o Valor do ICMS Normal do Valor do FCP retido por Substituição Tributária
            p_vlfecp              := NVL(p_vlfecp,0) - NVL(vnValorIcmsNormalFecp,0);
            IF (p_vlfecp < 0) THEN
              p_vlfecp := 0;
            END IF;
            
          END IF;
        
        END IF;
        
      EXCEPTION
        WHEN OTHERS THEN
          p_mensagem := 'Erro ao calcular ST Funcep: ' || SQLCODE || '-' ||
                        SQLERRM;
      END PCALCULARFUNCEP;  
      
    BEGIN
    
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             IF (NVL(pi_vOrdemCalculo,'F') = 'F') THEN
                                                                                                                                               P_INSERE_OPCAO_MEMORIA_CALCULO('Calcular ST Fonte ?', 'CALCULARST');          
                                                                                                                                             ELSE
                                                                                                                                               P_INSERE_OPCAO_MEMORIA_CALCULO('Calcular ST Fonte INVERSO ?', 'CALCULARST'); -- (Não mexer no texto "Calcular ST Fonte INVERSO ?", é usado para pintar o grid)
                                                                                                                                             END IF;
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('1) Sim, calcular ST Fonte com tributação ' || NVL(pio_nCodSt,0), 'CALCULARST', 'SIM');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('2) Sem ST Fonte por Isenção Órgão Público (Cliente x Tributação)', 'CALCULARST', 'NAO_ORGAOPUB');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('3) Sem ST Fonte por Regime Especial de Isenção ST (Cliente x Tributação)', 'CALCULARST', 'NAO_ISENCAO');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('4) Sem ST Fonte por Fabricante não Relevenda (Produto)', 'CALCULARST', 'NAO_RELEVANTE');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('5) Sem ST Fonte por Isenção para Bonificação (Tributação)', 'CALCULARST', 'NAO_ISEBNF'); -- MED-2521
    
      -- Iniciaiza Retornos com Regras da Tributação pra Gravação na PCPEDI                                          
      po_nAliqIcms1            := 0;
      po_nAliqIcms2            := 0;
      po_nIva                  := 0;
      po_nPercBaseRedStFonte   := 0;
    
      -- Atualiza variáveis locais que serão parâmetros de Entrada e Saída na FUNCOESVENDAS, 
      -- com valores passados nos Parâmetros de Entrada da Procedure
      n_ivafonte               := p_ivafonte;
      n_aliqicms1fonte         := p_aliqicms1fonte;
      n_aliqicms2fonte         := p_aliqicms2fonte;
      n_percbaseredstfonte     := p_percbaseredstfonte;
    
      -- Inicializa Retorno indicando como Padrão que não tem Isenção ST Fonte
      po_vRegimeEspIsenStFonte := 'N';
      
      -- Inicializa Variáveis de Cálculo do FUNCEP - HIS.04200.2017
      p_vlbasefcpicms          := 0;
      p_vlbasefcpst            := 0;
      p_vlbcfcpstret           := 0;
      p_perfcpstret            := 0;
      p_vlfcpstret             := 0;
      p_perfcpsn               := 0;
      p_vlfecp                 := 0;
      p_vlacrescimofuncep      := 0;
      p_vlcredfcpicmssn        := 0;    
      --
      po_nPerAcrescimoFuncep   := 0;    
      po_nAliqIcmsFecp         := 0;    
      po_nCodConfigFuncepMed   := NULL;
      
      -- Se Orgão Público e a Tributação tem Isenção de ST para Órgãos Públicos
      IF    ((NVL(p_tipoclimed, ' ') IN ('D','E','M')) AND  
             (NVL(p_isencaostorgaopub, ' ') = 'S')) THEN
    
        po_nBaseStFonte        := 0;
        po_nValorStFonte       := 0;
        po_nAliqIcms1          := 0;
        po_nAliqIcms2          := 0;
        po_nIva                := 0;
        po_nPercBaseRedStFonte := 0;
        po_vObservacaoStFonte  := 'Isenção Orgão Público';
               
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('CALCULARST', 'NAO_ORGAOPUB');                     
               
      -- Se Cliente Usa Regime Especial Isenção ST Fonte e
      -- Tributação com Regime Especial Isenção ST Fonte
      ELSIF ((NVL(p_usaregimeespisenstfonte,'N') = 'S') AND
             (NVL(p_regimeespisenstfonte,'N')    = 'S')) THEN
      
        po_nBaseStFonte          := 0;
        po_nValorStFonte         := 0;
        po_nAliqIcms1            := 0;
        po_nAliqIcms2            := 0;
        po_nIva                  := 0;
        po_nPercBaseRedStFonte   := 0;
        -- Atualiza Retorno indicando que vai aplicar Isenção ST Fonte
        po_vRegimeEspIsenStFonte := 'S';
        po_vObservacaoStFonte    := 'Regime Especial ST Fonte';
        
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('CALCULARST', 'NAO_ISENCAO');                     
        
      -- Fabricante NÃO RELEVANTE - HIS.03371.2017  
      ELSIF (NVL(p_indescalarelevante,'S') = 'N') THEN
  
        po_nBaseStFonte          := 0;
        po_nValorStFonte         := 0;
        po_nAliqIcms1            := 0;
        po_nAliqIcms2            := 0;
        po_nIva                  := 0;
        po_nPercBaseRedStFonte   := 0;
        po_vObservacaoStFonte    := 'Fabricante não Relevante';    
        
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('CALCULARST', 'NAO_RELEVANTE');                     
      
  
  
      -- MED-2521 - Isenção ST Bonificação
      ELSIF (NVL(p_isencaostfontebonificacao,'N') = 'S') AND
            ((NVL(p_itembonific,'N') IN ('S','F')) OR (NVL(pi_nCondVenda,0) = 5)) THEN -- DDMEDICA-198 - Incluído F
  
        po_nBaseStFonte          := 0;
        po_nValorStFonte         := 0;
        po_nAliqIcms1            := 0;
        po_nAliqIcms2            := 0;
        po_nIva                  := 0;
        po_nPercBaseRedStFonte   := 0;
        po_vObservacaoStFonte    := 'Isenção BNF';
  
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('CALCULARST', 'NAO_ISEBNF');
  
      ELSE     
  
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('CALCULARST', 'SIM');                     
  
        ----------------------------------------------------
        -- Recebe o Preço de Venda sem Impostos do Parâmetro
        ----------------------------------------------------
        vnPrecoVendaSemImpostos := NVL(p_pvenda,0);
      
        --------------------------------------------------
        -- C Á L C U L O    I N V E R S O    D O    S T -- 
        --------------------------------------------------
        IF (pi_vOrdemCalculo = 'I') THEN
        
          -- Alíquota FECP para somar na Alíq 1 do ST Fonte - MED-1930
          IF (NVL(p_participafuncep,'S')  = 'S') AND
             (NVL(p_codconfigfuncepmed,0) >  0 ) AND
             (NVL(p_aliqicmsfecp,0)       >  0 ) THEN
            vnAliq1StFonteFecp := (NVL(n_aliqicms1fonte,0) + NVL(p_aliqicmsfecp,0));
          ELSE
            vnAliq1StFonteFecp := NVL(n_aliqicms1fonte,0); -- Regra anterior.
          END IF;
  
          -- Chama Função para Calcular a Base e Valor do ST Fonte
          po_nValorStFonte := FCALCULARSTFONTE_INVERSO(pi_nValorNotaFiscal         ,
                                                       p_codprod                   ,
                                                       p_condvenda                 ,
                                                       p_percvenda                 ,
                                                       p_iva                       ,
                                                       n_ivafonte                  , --> Variável local no parâmetro de Entrada e Saída
                                                       vnAliq1StFonteFecp          , -- MED-1930 --> Variável local no parâmetro de Entrada e Saída
                                                       n_aliqicms2fonte            , --> Variável local no parâmetro de Entrada e Saída
                                                       n_percbaseredstfonte        , --> Variável local no parâmetro de Entrada e Saída
                                                       p_percbaserednrpa           ,
                                                       p_percbaseredconsumidor     ,
                                                       p_utilizapercbaseredpf_trib ,
                                                       p_tipocalcst                ,
                                                       p_calcstpf                  ,
                                                       p_utilizapercbaseredpf      ,
                                                       p_clientefontest            ,
                                                       p_calculast                 ,
                                                       p_ieent                     ,
                                                       p_tipofj                    ,
                                                       p_isentoicms                ,
                                                       p_consumidorfinal           ,
                                                       p_utilizaiesimplificada     ,
                                                       p_tipoempresa               ,
                                                       p_consideraisentoscomopf    ,
                                                       p_vlipi                     ,
                                                       p_uffilial                  ,
                                                       p_estent                    ,
                                                       p_usavalorultentbasest      ,
                                                       p_valorultent               ,
                                                       p_usaivafontediferenciado   ,
                                                       p_ivafonte_cli              ,
                                                       p_AceitaPFContribuinte      ,
                                                       p_ALIQICMS1                 ,
                                                       p_ALIQICMS2                 ,
                                                       p_contribuinte              ,
                                                       p_numcasasdecvenda          ,
                                                       po_nBaseStFonte             , -- MED-1930
                                                       po_vMensagem                , --> Variável local no parâmetro de Saída
                                                       p_custonfsemst              ,
                                                       p_usavalorultentbasest2     ,
                                                       p_usapmcbasest              ,
                                                       p_precomaxconsum            ,
                                                       p_usabaseicmsreduzida       ,
                                                       p_usabcrultent              ,
                                                       p_basebcrultent             ,
                                                       p_stbcrultent               ,                                        
                                                       p_CALCSTPAUTAFARMACIAPOPULAR,
                                                       p_PAUTAFONTE                ,
                                                       p_FARMACIAPOPULAR           ,
                                                       p_PARTICIPAFARMACIAPOPULAR  , 
                                                       p_usaptabelabasest          ,
                                                       p_SomenteIVATribut          , -- [HIS.05161.2014] 
                                                       p_usadescsimplesnac         , -- [HIS.05161.2014] 
                                                       p_simplesnacional           , -- [HIS.05161.2014] 
                                                       p_percredpvendasimplesnac   , -- [HIS.05161.2014] 
                                                       p_tipomerc                  ,
                                                       p_usarajusteprecocmed       ,
                                                       p_percajusteprecocmed       ,
                                                       p_medretirarstbnfestadual   ,
                                                       p_itembonific               ,
                                                       p_vlfreteoutrasdesp         ,
                                                       p_bnfnaocalculaicms         ,
                                                       p_USAREGSIMPLCARGATRIBSTFONTE , -- HIS.03187.2015
                                                       p_REGSIMPLCARGATRIBSTFONTE    , -- HIS.03187.2015
                                                       p_PERCREGSIMPLCARGATRIBSTFONTE, -- HIS.03187.2015     
                                                       p_USAREDUTORCAT49BASESTFONTE  , -- 5661.146071.2016
                                                       p_PERCREDUTORCAT49BASESTFONTE , -- 5661.146071.2016                                                             
                                                       p_USACARGAMINIMADEFERIMSTFONTE, -- HIS.01277.2017
                                                       p_PERCARGAMINIMADEFERIMSTFONTE, -- HIS.01277.2017     													   
                                                       p_USAVLSTMAIORPERCMINPMC, -- DDVENDAS-34782
                                                       p_PERVLSTMAIORPERCMINPMC, -- DDVENDAS-34782													   
                                                       p_codfilialfaturamento,         -- HIS.03371.2017
                                                       p_USAREDICMNORMVENDASTFONTE,    -- MED-1080
                                                       p_PERCBASERED,                  -- MED-1080
                                                       p_percipivenda,
                                                       p_usavlultentmediobasest, 
                                                       p_percbasestrj,
                                                       p_vlultentmes,
                                                       vnPrecoVendaSemImpostos,
                                                       p_participafuncep,
                                                       p_codconfigfuncepmed,
                                                       p_aliqicmsfecp,
                                                       p_vlfecp,
                                                       p_usapmpfbasest,
                                                       p_pmpf,
                                                       po_nPmPf,
                                                       p_desvincularFecpStFuncepICMS,
                                                       p_utilizaCustoContBaseST   ,
                                                       p_nFatorAjusteCustoCont     ,
                                                       p_ncustocont
                                                       );                       
              
        ------------------------------------------------
        -- C Á L C U L O    P A D R Ã O    D O    S T -- 
        ------------------------------------------------   
        ELSE
            
          -- Chama Função para Calcular a Base e Valor do ST Fonte
          po_nValorStFonte := FCALCULARSTFONTE(p_codprod                   ,
                                               p_condvenda                 ,
                                               p_percvenda                 ,
                                               p_iva                       ,
                                               n_ivafonte                  , --> Variável local no parâmetro de Entrada e Saída
                                               n_aliqicms1fonte            , --> Variável local no parâmetro de Entrada e Saída
                                               n_aliqicms2fonte            , --> Variável local no parâmetro de Entrada e Saída
                                               n_percbaseredstfonte        , --> Variável local no parâmetro de Entrada e Saída
                                               p_percbaserednrpa           ,
                                               p_percbaseredconsumidor     ,
                                               p_utilizapercbaseredpf_trib ,
                                               p_tipocalcst                ,
                                               p_calcstpf                  ,
                                               p_utilizapercbaseredpf      ,
                                               p_clientefontest            ,
                                               p_calculast                 ,
                                               p_ieent                     ,
                                               p_tipofj                    ,
                                               p_isentoicms                ,
                                               p_consumidorfinal           ,
                                               p_utilizaiesimplificada     ,
                                               p_tipoempresa               ,
                                               p_consideraisentoscomopf    ,
                                               vnPrecoVendaSemImpostos     , -->> PASSA O PREÇO DE VENDA SEM IMPOSTOS
                                               p_vlipi                     ,
                                               p_uffilial                  ,
                                               p_estent                    ,
                                               p_usavalorultentbasest      ,
                                               p_valorultent               ,
                                               p_usaivafontediferenciado   ,
                                               p_ivafonte_cli              ,
                                               p_AceitaPFContribuinte      ,
                                               p_ALIQICMS1                 ,
                                               p_ALIQICMS2                 ,
                                               p_contribuinte              ,
                                               p_numcasasdecvenda          ,
                                               po_nBaseStFonte             , -->> BASE ST FONTE QUE SERA RETORNADA PELA PROCEDURE
                                               vnPercBaseRedStFonteAlterado, -->> SE A LEGISLAÇÃO MUDAR O % DE REDUÇÃO DO CADASTRO - 5661.146071.2016
                                               po_vMensagem                , --> Variável local no parâmetro de Saída
                                               p_custonfsemst              ,
                                               p_usavalorultentbasest2     ,
                                               p_usapmcbasest              ,
                                               p_precomaxconsum            ,
                                               p_usabaseicmsreduzida       ,
                                               p_usabcrultent              ,
                                               p_basebcrultent             ,
                                               p_stbcrultent               ,                                        
                                               p_CALCSTPAUTAFARMACIAPOPULAR,
                                               p_PAUTAFONTE                ,
                                               p_FARMACIAPOPULAR           ,
                                               p_PARTICIPAFARMACIAPOPULAR  , 
                                               p_usaptabelabasest          ,
                                               p_ptabela                   ,
                                               p_SomenteIVATribut          ,
                                               p_usadescsimplesnac         ,
                                               p_simplesnacional           ,
                                               p_percredpvendasimplesnac   ,
                                               p_tipomerc                  ,
                                               p_usarajusteprecocmed       ,
                                               p_percajusteprecocmed       ,
                                               p_medretirarstbnfestadual   ,
                                               p_itembonific               ,
                                               p_vlfreteoutrasdesp         ,
                                               p_bnfnaocalculaicms         ,
                                               p_USAREGSIMPLCARGATRIBSTFONTE ,
                                               p_REGSIMPLCARGATRIBSTFONTE    ,
                                               p_PERCREGSIMPLCARGATRIBSTFONTE,
                                               p_USAREDUTORCAT49BASESTFONTE  ,
                                               p_PERCREDUTORCAT49BASESTFONTE ,
                                               p_USACARGAMINIMADEFERIMSTFONTE,
                                               p_PERCARGAMINIMADEFERIMSTFONTE,											   
                                               p_USAVLSTMAIORPERCMINPMC,
                                               p_PERVLSTMAIORPERCMINPMC,											   											   
                                               p_pautafonteaplicado,
                                               po_vObservacaoStFonte,
                                               p_codfilialfaturamento,
                                               p_USAREDICMNORMVENDASTFONTE,
                                               p_PERCBASERED,
                                               p_percipivenda,
                                               p_usavlultentmediobasest, 
                                               p_percbasestrj,
                                               p_vlultentmes,
                                               vnRetVlFreteOutrasDespBaseSt,
                                               vnRetPercBaseRedIcmsFecp,
                                               v_usaReducaoBasePmc,
                                               v_pertetoredbasepmc,
                                               p_usapmpfbasest,
                                               p_pmpf,
                                               p_agregapiscofinsst1,
                                               p_agregasuframast1,
                                               p_agregaicmsisencaost1,
                                               p_agregapiscofinsst2,
                                               p_agregasuframast2,
                                               p_agregaicmsisencaost2,
                                               p_vldescreducaopis,
                                               p_vldescreducaocofins,
                                               p_vldescicmisencao,
                                               p_vldescsuframa,
                                               vvRetEnquadraIcmsSubstAnterior,
                                               vnRetVlIcmsSubstitutoAnterior,
                                               po_nPmPf,
                                               p_utilizaCustoContBaseST,
                                               p_nFatorAjusteCustoCont,
											   p_ncustocont  );
          -- Regras da Tributação pra Gravação na PCPEDI
          po_nAliqIcms1          := n_aliqicms1fonte;
          po_nAliqIcms2          := n_aliqicms2fonte;
          po_nIva                := n_ivafonte;
          po_nPercBaseRedStFonte := n_percbaseredstfonte;
          po_nPautaFonte         := p_pautafonteaplicado;
                            
          -->> SE A LEGISLAÇÃO MUDAR O % DE REDUÇÃO DO CADASTRO
          IF (vnPercBaseRedStFonteAlterado IS NOT NULL) THEN
            IF (p_USAREDUTORCAT49BASESTFONTE = 'S') THEN
              po_nPercBaseRedStFonte := vnPercBaseRedStFonteAlterado;
              po_vObservacaoStFonte  := po_vObservacaoStFonte || ',Red.Cat49';
            END IF;
          END IF;
          
          -- Se não houve erro no Cálculo do ST
          IF (po_vMensagem IS NULL) THEN
          
            -- FUNCEP com Fórmula com Motor de Cálculo
            IF ((NVL(p_participafuncep,'S')  = 'S') OR 
              ((NVL(p_desvincularFecpStFuncepICMS,'N')  = 'S')
                AND (NVL(p_participafuncep,'S')  = 'N'))) AND 
               (NVL(p_clientefontest,'N')   = 'S') AND
               (NVL(p_codconfigfuncepmed,0) >  0 ) AND
               (NVL(p_aliqicmsfecp,0)       >  0 ) THEN
            
              -- Chama Procedimento para Calcular os Valores do FUNCEP
              PCALCULARFUNCEP(p_codconfigfuncepmed,
                              po_nBaseStFonte,
                              vnPrecoVendaSemImpostos, -->> PASSA O PREÇO DE VENDA SEM IMPOSTOS
                              po_vObservacaoStFonte, 
                              p_aliqicmsfecp,
                              p_vlbasefcpicms,
                              p_vlbasefcpst,
                              p_vlbcfcpstret,
                              p_perfcpstret,
                              p_perfcpsn,
                              p_vlfecp,
                              p_vlacrescimofuncep,
                              p_vlcredfcpicmssn,
                              po_vMensagem,
                              vnRetVlFreteOutrasDespBaseSt,
                              vnRetPercBaseRedIcmsFecp); 
    
              -- Atualiza Variáveis de Cálculo do FUNCEP - HIS.04200.2017
              po_nPerAcrescimoFuncep := 0; -- MED-656 ->> Percentual de ICMS do FUNCEP - Ficou sendo gravado no Faturamento, junto com a Base e Valor do ICMS o FUNCEP
              IF (NVL(p_vlbasefcpst,0) = 0) THEN
                po_nAliqIcmsFecp     := 0; -->> Se não tiver base não vai ter alíquota do ST do Funcep MED-1471
              ELSE
                po_nAliqIcmsFecp     := p_aliqicmsfecp;
              END IF;            
              po_nCodConfigFuncepMed := p_codconfigfuncepmed;                                             
                                                          
            END IF; -- Fim Condição: FUNCEP com Fórmula com Motor de Cálculo
            
          END IF; -- Fim Condição: Se não houve erro no Cálculo do ST
          
          ----------------------------------
          -- CÁLCULO ST GNRE - DDMEDICA-7697
          ----------------------------------
          IF (NVL(v_tipocalculognre,'P') = 'C') THEN
          
            -- ST CLIENTE GNRE
            po_nStClienteGnre            := po_nValorStFonte;
            -- Sem ST Próprio
            po_nBaseStFonte              := 0;
            po_nValorStFonte             := 0;
            po_nAliqIcms1                := 0;
            po_nAliqIcms2                := 0;
            po_nIva                      := 0;
            po_nPercBaseRedStFonte       := 0;
            -- Sem ST Antecipado
            po_nBcStRetAnterior          := 0;
            po_nVlIcmsSubstitutoAnterior := 0;
            po_nVlIcmsStRetAnterior      := 0;
          
            po_vObservacaoStFonte := po_vObservacaoStFonte || ',STGnre';
          
          ---------------------------------------------------
          -- ST Recolhido Anteriormente (Ajuste SINIEF 01/94)
          ---------------------------------------------------
          ELSIF (NVL(v_destacicmsstanterior,'N') = 'S') THEN
          
            -- Enquadrado no Cálculo do ST Padrão
            IF (NVL(vvRetEnquadraIcmsSubstAnterior,'N') = 'S') THEN
  
              -- Os valores calculados de ST serão gravados em campos separados          
              po_nBcStRetAnterior          := po_nBaseStFonte;
              po_nVlIcmsSubstitutoAnterior := vnRetVlIcmsSubstitutoAnterior;
              po_nVlIcmsStRetAnterior      := po_nValorStFonte;
              
              -- Serão zerados os valores calculados de ST
              -- menos o po_nAliqIcms1 que precisarei dele no DANFE - DDVENDAS-31441
              po_nBaseStFonte              := 0;
              po_nValorStFonte             := 0;
              po_nAliqIcms2                := 0;
              po_nIva                      := 0;
              po_nPercBaseRedStFonte       := 0;
              po_vObservacaoStFonte        := po_vObservacaoStFonte || ',StRecolhidoAnt';
              
            -- Não está enquadrado no ST Padrão (Possui uma Exceção à Regra)
            ELSE
            
              po_vObservacaoStFonte        := po_vObservacaoStFonte || ',ExcStRecAnt';
              
            END IF;
            
          END IF;
  
        END IF; -- Fim Condição - Cálculo Inverso do ST
                                                                                 
      END IF;
    
    EXCEPTION
      WHEN OTHERS THEN  
        -- Sem ST
        po_nBaseStFonte  := 0;
        po_nValorStFonte := 0;
        po_vMensagem     := 'Erro cálculo ST Fonte: ' || SUBSTR('Erro: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ' >> ' || SQLERRM,1,240);
    END P_OBTER_STFONTE;
  
   /***************************************************************************
    ***************************************************************************
    **                  INICIO DO PROCESSAMENTO PRINCIPAL                    **
    ***************************************************************************                  
    ***************************************************************************/
  BEGIN
  
    -- Inicializa Retornos
    po_nBaseStFonte    := 0;
    po_nValorStFonte   := 0;
    po_vMensagem       := NULL;
    po_vClienteFonteSt := 'N';
  
   /****************************
    Inicializa Tabela Temporária
    ****************************/
  
    -- Limpa Tabela Temporaria de Memoria de Cálculo
    IF (pi_vMemoriaCalculo = 'S') THEN
      DELETE FROM PCMED_MEMORIA_CALCULO_ST
       WHERE (CODPROD <> pi_nCodProd)
         AND (SUBSTR(ORIGEM,1,1) = 'S');
      DELETE FROM PCMED_MEMORIA_CALCULO_ST
       WHERE (ORIGEM = ('S'||pi_vOrdemCalculo));
    END IF;
  
   /************************************************
    Código da Filial de Faturamento - HIS.03371.2017
    ************************************************/
    vvCodFilialFaturamento := NVL(pi_nCodFilialNf,pi_vCodFilial);
  
   /*******************
    Pesquisa Parâmetros
    *******************/
    BEGIN
      SELECT TIPOCALCST
           , CALCSTFONTEPF
           , CALCSTPF
           , NVL(UTILIZAPERCBASEREDPF,'N') UTILIZAPERCBASEREDPF
           , CONSIDERAISENTOSCOMOPF
           , ACEITAPFCONTRIBUINTE
           , NVL(NUMCASASDECVENDA,2) NUMCASASDECVENDA
           , NVL(USATRIBUTACAOPORUF,'N') USATRIBUTACAOPORUF
           , TIPOCALCSULFRAMA -- DDMEDICA-7594
        INTO v_tipocalcst
           , v_calcstfontepf
           , v_calcstpf
           , v_utilizapercbaseredpf_param
           , v_consideraisentoscomopf
           , v_AceitaPFContribuinte
           , v_numcasasdecvenda
           , v_usatributacaoporuf
           , v_tipocalcsulframa -- DDMEDICA-7594
        FROM PCCONSUM;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        po_vMensagem := 'Não foram encontrados dados na PCCONSUM';
        RAISE e_tratado;
    END;
    --
    BEGIN
      SELECT NVL(VALOR,'N') VALOR
        INTO v_calcstpautafarmaciapopular
        FROM PCPARAMFILIAL
       WHERE (CODFILIAL = '99')
         AND (NOME      = 'CALCSTPAUTAFARMACIAPOPULAR');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_calcstpautafarmaciapopular := 'N';
    END;         
    --
    BEGIN
      SELECT NVL(VALOR,'S') VALOR
        INTO v_usadescsimplesnac
        FROM PCPARAMFILIAL
       WHERE (CODFILIAL = vvCodFilialFaturamento) -- HIS.03371.2017
         AND (NOME      = 'USADESCSIMPLESNAC');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_usadescsimplesnac := 'N';
    END;
    --
    BEGIN
      SELECT NVL(VALOR,'N') VALOR
        INTO v_medretirarstbnfestadual
        FROM PCPARAMFILIAL
       WHERE (CODFILIAL = vvCodFilialFaturamento) -- HIS.03371.2017
         AND (NOME      = 'MEDRETIRARSTBNFESTADUAL');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_medretirarstbnfestadual := 'N';
    END;
    
    BEGIN
      SELECT NVL(VALOR,'N') VALOR
        INTO v_medcalcularstpelopeps
        FROM PCPARAMFILIAL
       WHERE (CODFILIAL = vvCodFilialFaturamento) -- HIS.03371.2017
         AND (NOME      = 'MEDCALCULARSTPELOPEPS');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_medcalcularstpelopeps := 'N';
    END;
    
   /*************************
    Pesquisa Dados do Cliente
    *************************/
    BEGIN
      SELECT ESTENT
           , CODPRACA      
           , NVL(CLIENTEFONTEST,'N') CLIENTEFONTEST   
           , NVL(CALCULAST,'S') CALCULAST
           , UPPER(IEENT) IEENT
           , TIPOFJ
           , NVL(ISENTOICMS,'N') ISENTOICMS
           , CONSUMIDORFINAL
           , NVL(UTILIZAIESIMPLIFICADA,'N') UTILIZAIESIMPLIFICADA
           , TIPOEMPRESA
           , NVL(USAIVAFONTEDIFERENCIADO,'N') USAIVAFONTEDIFERENCIADO
           , NVL(IVAFONTE,0) IVAFONTE_CLI
           , NVL(CONTRIBUINTE,'S') CONTRIBUINTE
           , TIPOCLIMED
           , PARTICIPAFARMACIAPOPULAR
           , SIMPLESNACIONAL -- [HIS.05161.2014]
           , NVL(USAREGIMEESPISENSTFONTE,'N')  
           , NVL(USAREGSIMPLCARGATRIBSTFONTE,'N') -- HIS.03187.2015 
           , NVL(PCCLIENT.PARTICIPAFUNCEP,'N') -- HIS.04200.2017
           -- DDMEDICA-7594
           , PCCLIENT.SULFRAMA
           , PCCLIENT.ORGAOPUB
           , PCCLIENT.ORGAOPUBFEDERAL
           , PCCLIENT.ORGAOPUBMUNICIPAL
           , PCCLIENT.TIPODESCISENCAO
           , PCCLIENT.PERDESCISENTOICMS
        INTO v_estent
           , v_codpraca
           , v_clientefontest
           , v_calculast
           , v_ieent
           , v_tipofj
           , v_isentoicms
           , v_consumidorfinal
           , v_utilizaiesimplificada
           , v_tipoempresa
           , v_usaivafontediferenciado
           , v_ivafonte_cli
           , v_contribuinte
           , v_tipoclimed
           , v_participafarmaciapopular
           , v_simplesnacional -- [HIS.05161.2014]
           , v_usaregimeespisenstfonte
           , vUSAREGSIMPLCARGATRIBSTFONTE -- HIS.03187.2015 
           , v_participafuncep -- HIS.04200.2017
           -- DDMEDICA-7594
           , v_sulframa
           , v_orgaopub
           , v_orgaopubfederal
           , v_orgaopubmunicipal           
           , v_tipodescisencao           
           , v_perdescisentoicms
        FROM PCCLIENT
       WHERE (CODCLI = pi_nCodCli);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        po_vMensagem := 'Não foram encontrados dados do Cliente ' || NVL(pi_nCodCli,0);
        RAISE e_tratado;
    END;
    
    -- DDVENDAS-33718 - UF do Endereço de Entrega do Cliente
    IF (pi_vEstEnt IS NOT NULL) THEN
      v_estent := pi_vEstEnt;     
    END IF;
  
   /************************************
    Pesquisa Dados do Cliente por Filial
    ************************************/
    BEGIN
      SELECT NVL(PCCLIENTFILIALMED.CLIENTEFONTEST,'N')
        INTO v_clientefontest
        FROM PCCLIENTFILIALMED
       WHERE (PCCLIENTFILIALMED.CODCLI    = pi_nCodCli)
         AND (PCCLIENTFILIALMED.CODFILIAL = vvCodFilialFaturamento); -- HIS.03371.2017
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -->> Se não encontrar exceção por Filial, Mantém os valores da PCCLIENT
        NULL;
    END;
    
   /*************************************************
    Retornará se o Cliente é ST Fonte - DDMEDICA-7697
    *************************************************/
    po_vClienteFonteSt := v_clientefontest; 
  
   /************************
    Pesquisa Dados da Filial
    ************************/
    BEGIN
      SELECT UF
           , DTULTPROCESSAMENTOPEPS 
        INTO v_uffilial
           , v_dtultprocessamentopeps
        FROM PCFILIAL
       WHERE (CODIGO = vvCodFilialFaturamento); -- HIS.03371.2017
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        po_vMensagem := 'Não foram encontrados dados para a Filial: ' || NVL(vvCodFilialFaturamento,' '); -- HIS.03371.2017
        RAISE e_tratado;
    END;
  
   /*************************
    Pesquisa Dados do Produto
    *************************/
    BEGIN
      SELECT FARMACIAPOPULAR
           , TIPOMERC
           , PERCIPIVENDA
        INTO v_farmaciapopular
           , v_tipomerc
           , v_percipivenda
        FROM PCPRODUT
       WHERE (CODPROD = pi_nCodProd);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_farmaciapopular := 'N';
        v_tipomerc        := ' ';
        v_percipivenda    := NULL;
    END;
  
   /*****************************************************
    Pesquisa Dados do Produto por Filial - HIS.03371.2017
    *****************************************************/
    BEGIN
      SELECT NVL(PCPRODFILIAL.INDESCALARELEVANTE,'S') -->> PADRÃO SIM PARA CALCULAR ST (INDUSTRIA FARMACEUTICA RELEVANTE)
           , PCPRODFILIAL.CNPJFABRICANTE 
           , PCPRODFILIAL.FABRICANTE 
        INTO po_vIndEscalaRelevante
           , po_vCnpjFabricante
           , po_vFabricante
        FROM PCPRODFILIAL
       WHERE (CODPROD   = pi_nCodProd)
         AND (CODFILIAL = vvCodFilialFaturamento); -- HIS.03371.2017
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        po_vIndEscalaRelevante := 'S'; -->> PADRÃO SIM PARA CALCULAR ST (INDUSTRIA FARMACEUTICA RELEVANTE)
        po_vCnpjFabricante     := NULL;
        po_vFabricante         := NULL;
    END;
    
   /*******************
    Pesquisa Tributação
    *******************/
    
    -- Pega a Região do Parâmetro
    v_numregiao := pi_nNumRegiao;
    
    -- Se NÃO passou a Tributação do Parâmetro
    IF (NVL(pio_nCodSt,0) = 0) THEN
      
      ---------------------------
      -- Se usa Tributação por UF
      ---------------------------
      IF (NVL(v_usatributacaoporuf,'N') = 'S') THEN
      
        -- Pesquisa Tributação por UF
        BEGIN
          SELECT CODST
            INTO pio_nCodSt
            FROM PCTABTRIB
           WHERE (CODPROD     = pi_nCodProd)
             AND (UFDESTINO   = v_estent)
             AND (CODFILIALNF = vvCodFilialFaturamento); -- HIS.03371.2017
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            po_vMensagem := 'Não foi encontrada Tributação para o Produto ' || NVL(pi_nCodProd,0) || ', UF Destino [' || NVL(v_estent,' ') || '] e UF Filial [' || NVL(v_uffilial,' ' ||']');
            RAISE e_tratado;
        END;
            
      -------------------------------
      -- Se NÃO usa Tributação por UF
      -------------------------------
      ELSE
      
        -- Se passou a Região no Parâmetro
        IF (NVL(pi_nNumRegiao,0) > 0) THEN
        
          v_numregiao := pi_nNumRegiao;
          
        -- Se NÃO passou a Região no Parâmetro
        ELSE
      
          -- Pesquisa Região do Cliente por Filial
          BEGIN
            SELECT NUMREGIAO
              INTO v_numregiao
              FROM PCTABPRCLI
             WHERE (CODCLI      = pi_nCodCli)
               AND (CODFILIALNF = vvCodFilialFaturamento); -- HIS.03371.2017
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              v_numregiao := NULL;
          END;
        
          -- Se não achou Regiao do Cliente por Filial
          IF (v_numregiao IS NULL) THEN
            -- Pesquisa Região da Praça
            BEGIN
              SELECT NUMREGIAO
                INTO v_numregiao
                FROM PCPRACA
               WHERE (CODPRACA = v_codpraca);
            EXCEPTION
             WHEN NO_DATA_FOUND THEN
                v_numregiao := NULL;
            END;
          END IF;
          
        END IF; -- Fim Condição Se passou a Região no Parâmetro        
      
        -- Pesquisa Tributação por Região
        BEGIN
          SELECT CODST
            INTO pio_nCodSt
            FROM PCTABPR
           WHERE (CODPROD   = pi_nCodProd)
             AND (NUMREGIAO = v_numregiao);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            po_vMensagem := 'Não foi encontrada Tributação para o Produto ' || NVL(pi_nCodProd,0) || ' e Região ' || NVL(v_numregiao,0);
            RAISE e_tratado;
        END;
          
      END IF; -- Fim Condição v_usatributacaoporuf
      
    END IF; -- Fim Condição Se passou a Tributação do Parâmetro
  
   /***********************************
    Pesquisa Preço Máximo do Consumidor
    ***********************************/
    
    -- Se passou o Preço Máximo do Consumidor no Parâmetro
    IF (NVL(pi_nPrecoMaxConsum,0) > 0) THEN
  
      -- Pega valor do parâmetro  
      v_precomaxconsum := NVL(pi_nPrecoMaxConsum,0);
      
    -- NÃO passou o Preço Máximo do Consumidor no Parâmetro
    ELSE
  
      -------------------
      -- Obtem PMC por UF
      -------------------
      P_OBTEM_PMC_PRODUTO(vvCodFilialFaturamento, -- HIS.03371.2017
                          pi_nCodProd,
                          v_estent,
                          pi_nNumRegiao,
                          v_precomaxconsum,
                          v_precofabrica,
                          vvMensagemPmc,
                          pi_nCodCli); -- DDVENDAS-35830
      IF (vvMensagemPmc IS NOT NULL) THEN
        po_vMensagem := vvMensagemPmc; 
        RAISE e_tratado;
      END IF;                              
  
    END IF; -- Fim Condição Se passou o Preço Máximo do Consumidor no Parâmetro
      
   /*************************
    Pesquisa Valores da PCEST
    *************************/
    
    -- Se passou dados da PCEST no parâmetro
    --IF (pi_nValorUltEnt  IS NOT NULL) AND
    --   (pi_nCustoNfSemSt IS NOT NULL) THEN
    --   
    --  -- Pega Valores do Parâmetro  
    --  v_valorultent  := NVL(pi_nValorUltEnt,0);   
    --  v_custonfsemst := NVL(pi_nCustoNfSemSt,0);   
    --   
    -- Se NÃO passou dados da PCEST no parâmetro
    --ELSE 
    
      -- Pesquisa Dados da PCEST
      BEGIN
        SELECT VALORULTENT
             , CUSTONFSEMST
             , BASEBCR
             , STBCR
			 , CUSTOCONT
          INTO v_valorultent
             , v_custonfsemst
             , n_basebcrultent
             , n_stbcrultent
			 , v_ncustocont
          FROM PCEST
         WHERE (CODFILIAL = vvCodFilialFaturamento) -- HIS.03371.2017
           AND (CODPROD   = pi_nCodProd);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_valorultent   := 0; 
          v_custonfsemst  := 0;
          n_basebcrultent := 0;
          n_stbcrultent   := 0;
      END;
      
    --END IF; -- Fim Condição Se passou dados da PCEST no parâmetro     
    
   /****************************
    Pesquisa dados da Tributação
    ****************************/
    BEGIN
      SELECT IVA
           , NVL(IVAFONTE,0) IVAFONTE
           , NVL(ALIQICMS1FONTE,0) ALIQICMS1FONTE
           , NVL(ALIQICMS2FONTE,0) ALIQICMS2FONTE
           , NVL(PERCBASEREDSTFONTE,0) PERCBASEREDSTFONTE
           , NVL(PERBASEREDNRPA,0) PERBASEREDNRPA
           , NVL(PERCBASEREDCONSUMIDOR,0) PERCBASEREDCONSUMIDOR
           , NVL(UTILIZAPERCBASEREDPF,'N') UTILIZAPERCBASEREDPF
           , NVL(USAVALORULTENTBASEST,'N') USAVALORULTENTBASEST
           , NVL(ALIQICMS1,0) ALIQICMS1
           , NVL(ALIQICMS2,0) ALIQICMS2
           , NVL(USAVALORULTENTBASEST2, 'N') USAVALORULTENTBASEST2
           , NVL(USAPMCBASEST,'N') USAPMCBASEST
           , ISENCAOSTORGAOPUB
           , USABASEICMSREDUZIDA
           , USABCRULTENT
           , NVL(PAUTAFONTE,0) PAUTAFONTE         
           , USAPTABELABASEST  
           , NVL(PERCREDPVENDASIMPLESNAC,0) PERCREDPVENDASIMPLESNAC
           , NVL(PCTRIBUT.USARAJUSTEPRECOCMED,'N') USARAJUSTEPRECOCMED
           , NVL(PCTRIBUT.PERCAJUSTEPRECOCMED,0) PERCAJUSTEPRECOCMED
           , NVL(PCTRIBUT.REGIMEESPISENSTFONTE,'N') REGIMEESPISENSTFONTE         
           , NVL(PCTRIBUT.BNFNAOCALCULAICMS,'N') BNFNAOCALCULAICMS
           , NVL(PCTRIBUT.PERCBASEREDST,0) PERCBASEREDST
           , NVL(PCTRIBUT.REGSIMPLCARGATRIBSTFONTE,'N') REGSIMPLCARGATRIBSTFONTE
           , NVL(PCTRIBUT.PERCREGSIMPLCARGATRIBSTFONTE,0) PERCREGSIMPLCARGATRIBSTFONTE
           , NVL(PCTRIBUT.USAREGRADIFSTFONTETV10,'N') USAREGRADIFSTFONTETV10
           , PCTRIBUT.USAREDUTORCAT49BASESTFONTE
           , PCTRIBUT.PERCREDUTORCAT49BASESTFONTE
           , PCTRIBUT.USACARGAMINIMADEFERIMSTFONTE
           , PCTRIBUT.PERCARGAMINIMADEFERIMSTFONTE		   
           , PCTRIBUT.USAVLSTMAIORPERCMINPMC
           , PCTRIBUT.PERVLSTMAIORPERCMINPMC
           , PCTRIBUT.UTILIZAMOTORCALCULO
           , PCTRIBUT.FORMULAPVENDA
           , PCTRIBUT.PERACRESCIMOFUNCEP
           , PCTRIBUT.ALIQICMSFECP
           , PCTRIBUT.CODCONFIGFUNCEPMED           
           , NVL(PCTRIBUT.USAREDICMNORMVENDASTFONTE,'N') USAREDICMNORMVENDASTFONTE
           , NVL(PCTRIBUT.PERCBASERED,0)                 PERCBASERED
           , NVL(PCTRIBUT.USAVLULTENTMEDIOBASEST,'N')
           , PCTRIBUT.PERCBASESTRJ,
             PCTRIBUT.USAREDUCAOBASEPMC,
             PCTRIBUT.PERTETOREDBASEPMC
           , NVL(PCTRIBUT.ISENCAOSTFONTEBONIFICACAO,'N')
           , PCTRIBUT.PERCBASEREDST_MC
           , PCTRIBUT.IVA_MC
           , PCTRIBUT.PAUTA_MC    
           , PCTRIBUT.ALIQICMS1_MC      
           , PCTRIBUT.ALIQICMS2_MC 
           , PCTRIBUT.USARABAPERDASTFONTEPEDAVARIA
           , NVL(USAPMPFBASEST,'N') USAPMPFBASEST
           , PCTRIBUT.AGREGAPISCOFINSST1
           , PCTRIBUT.AGREGASUFRAMAST1
           , PCTRIBUT.AGREGAICMSISENCAOST1
           , PCTRIBUT.AGREGAPISCOFINSST2   
           , PCTRIBUT.AGREGASUFRAMAST2
           , PCTRIBUT.AGREGAICMSISENCAOST2
           , PCTRIBUT.PERDESCSUFRAMA
           , PCTRIBUT.PERDESCPISSUFRAMA
           , PCTRIBUT.PERCDESCPIS
           , PCTRIBUT.PERCDESCCOFINS
           , PCTRIBUT.PERDESCICMISENCAO
           , PCTRIBUT.APLICADESCISENCAOMED           
           , PCTRIBUT.DESTACDESCICMISENCAOCOMERCIAL
           , NVL(PCTRIBUT.DESTACICMSSTANTERIOR,'N')
           , NVL(PCTRIBUT.TIPOCALCULOGNRE,'P')
		   , NVL(PCTRIBUT.DESVINCULARFECPSTFUNCEPICMS,'N') DESVINCULARFECPSTFUNCEPICMS																		  
           , NVL(PCTRIBUT.Utilizarcustocontbasest,'N') Utilizarcustocontbasest
		   , NVL(PCTRIBUT.FATORAJUSTECUSTOCONT,0) FATORAJUSTECUSTOCONT
        INTO v_iva
           , v_ivafonte
           , v_aliqicms1fonte
           , v_aliqicms2fonte
           , v_percbaseredstfonte
           , v_percbaserednrpa
           , v_percbaseredconsumidor
           , v_utilizapercbaseredpf_trib
           , v_usavalorultentbasest
           , v_ALIQICMS1
           , v_ALIQICMS2
           , v_usavalorultentbasest2
           , v_usapmcbasest
           , v_isencaostorgaopub
           , v_usabaseicmsreduzida
           , v_usabcrultent
           , n_pautafonte
           , v_usaptabelabasest  
           , n_percredpvendasimplesnac
           , v_usarajusteprecocmed
           , n_percajusteprecocmed         
           , v_regimeespisenstfonte
           , v_bnfnaocalculaicms
           , v_percbaseredst
           , vREGSIMPLCARGATRIBSTFONTE
           , nPERCREGSIMPLCARGATRIBSTFONTE
           , vUSAREGRADIFSTFONTETV10
           , vUSAREDUTORCAT49BASESTFONTE
           , nPERCREDUTORCAT49BASESTFONTE
           , vUSACARGAMINIMADEFERIMSTFONTE
           , nPERCARGAMINIMADEFERIMSTFONTE	   
           , vUSAVLSTMAIORPERCMINPMC
           , nPERVLSTMAIORPERCMINPMC
           , v_utilizamotorcalculo
           , v_formulapvenda
           , v_peracrescimofuncep
           , v_aliqicmsfecp
           , v_codconfigfuncepmed
           , vUSAREDICMNORMVENDASTFONTE
           , vPERCBASERED
           , v_usavlultentmediobasest
           , n_percbasestrj
           , v_usaReducaoBasePmc
           , v_pertetoredbasepmc
           , v_isencaostfontebonificacao
           , v_percbaseredst_mc
           , v_iva_mc
           , v_pauta_mc    
           , v_aliqicms1_mc      
           , v_aliqicms2_mc 
           , vUSARABAPERDASTFONTEPEDAVARIA           
           , v_usapmpfbasest
           , v_agregapiscofinsst1
           , v_agregasuframast1
           , v_agregaicmsisencaost1
           , v_vagregapiscofinsst2
           , v_agregasuframast2
           , v_agregaicmsisencaost2
           , v_perdescsuframa
           , v_perdescpissuframa
           , v_percdescpis
           , v_percdesccofins
           , v_perdescicmisencao
           , v_aplicadescisencaomed           
           , v_destacdescicmisencaocomerc
           , v_destacicmsstanterior
           , v_tipocalculognre
		   , v_desvincularFecpSTFuncepICMS							  
		   , v_utilizaCustoContBaseST
		   , vnFatorAjusteCustoCont							   
        FROM PCTRIBUT
       WHERE (CODST = pio_nCodSt);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        po_vMensagem := 'Não foram encontrados dados para a Tributação: ' || NVL(pio_nCodSt,0);
        RAISE e_tratado;
    END;     
    
	IF (NVL(v_utilizaCustoContBaseST,'N')= 'S') and (v_aliqicms1fonte = 0) THEN
      v_aliqicms1fonte := v_ALIQICMS1;
    END IF;
   /***************************************
    Pesquisa PMC quando a Tributação a usar
    ***************************************/
    vnPmPf := NULL;
    IF (v_usapmpfbasest = 'S') THEN
      P_OBTEM_PMPF(pio_nCodSt,
                   pi_nCodProd,
                   pi_nCodCli,                             
                   vnPmPf,
                   v_estent); -- DDVENDAS-33718
      -- DDVENDAS-34479
      IF (NVL(pi_nQtUnitEmb,0) > 1) THEN
        vnPmPf := ROUND((NVL(vnPmPf,0) * NVL(pi_nQtUnitEmb,0)),v_numcasasdecvenda);
      END IF;
    END IF;
                 
   /***************************
    Pesquisa Valores da PCTABPR
    ***************************/
    n_vlultentmes := 0;
    IF (NVL(v_usavlultentmediobasest,'N') = 'S') THEN
    
      -- Se chegou aqui sem a Região
      IF (NVL(v_numregiao,0) = 0) THEN
    
        -- Pesquisa Região do Cliente por Filial
        BEGIN
          SELECT NUMREGIAO
            INTO v_numregiao
            FROM PCTABPRCLI
           WHERE (CODCLI      = pi_nCodCli)
             AND (CODFILIALNF = vvCodFilialFaturamento); -- HIS.03371.2017
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_numregiao := NULL;
        END;
      
        -- Se não achou Regiao do Cliente por Filial
        IF (v_numregiao IS NULL) THEN
          -- Pesquisa Região da Praça
          BEGIN
            SELECT NUMREGIAO
              INTO v_numregiao
              FROM PCPRACA
             WHERE (CODPRACA = v_codpraca);
          EXCEPTION
           WHEN NO_DATA_FOUND THEN
              v_numregiao := NULL;
          END;
        END IF;
        
      END IF; -- Fim Condição Se passou a Região no Parâmetro        
    
      -- Pesquisa dados da Região
      BEGIN
        SELECT VLULTENTMES
          INTO n_vlultentmes
          FROM PCTABPR
         WHERE (CODPROD   = pi_nCodProd)
           AND (NUMREGIAO = v_numregiao);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          n_vlultentmes := 0;
      END;
    END IF;
      
   /***************************************************************************
                  Calcula como se Fosse ST Fonte - HIS.01858.2015
    (Operador Logistico por Preço Fábrica, mas Trabalha com ST na Precificação)
    ***************************************************************************/
    IF (pi_vTipoChamada = 'L') THEN
    
      -- Trata o Cálculo como se fosse um Cliente ST Fonte
      v_clientefontest := 'S';
    
    END IF;
    
    /***************************************************************************
                 Utilizar ST Fonte SIMPLES Nacional [HIS.04322.2015]
    ***************************************************************************/
  
    -- Se Cliente for SIMPLES Nacional 
    IF v_simplesnacional = 'S' THEN    
      BEGIN   
        -- Busca Parâmetro
        SELECT NVL(VALOR,'N')         
          INTO v_medutilizarstfontesimplesnac
          FROM PCPARAMFILIAL
         WHERE NOME = 'MEDUTILIZARSTFONTESIMPLESNAC'
           AND CODFILIAL = '99';
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_medutilizarstfontesimplesnac := 'N';
      END;
      
      -- Se Utilizar, substitui as variáveis para fazer o cálculo
      IF v_medutilizarstfontesimplesnac = 'S' THEN    
        BEGIN
          SELECT NVL(IVAFONTESIMPLESNAC,0)
               , NVL(ALIQICMS1FONTESIMPLESNAC,0)
               , NVL(ALIQICMS2FONTESIMPLESNAC,0)
               , NVL(PERCBASEREDSTFONTESIMPLESNAC,0)
               , NVL(PAUTAFONTESIMPLESNAC,0)
            INTO v_ivafonte
               , v_aliqicms1fonte
               , v_aliqicms2fonte
               , v_percbaseredstfonte
               , n_pautafonte
            FROM PCTRIBUT 
         WHERE (CODST = pio_nCodSt);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            po_vMensagem := 'Não foram encontrados dados para a Tributação SIMPLES NACIONAL: ' || NVL(pio_nCodSt,0);
          RAISE e_tratado;
        END;
      END IF; -- Fim-Se Utilizar ST Fonte SIMPLES Nacional
    END IF; -- Fim-se Cliente SIMPLES Nacional    
    
    -- 4415.073219.2016 - Se Utiliza Regra Diferenciada de ST Fonte na Transferência
    IF (pi_nCondVenda = 10) AND 
       (vUSAREGRADIFSTFONTETV10 = 'S') THEN    
      -- Se Utilizar, substitui as variáveis para fazer o cálculo
      BEGIN
        SELECT NVL(IVAFONTETV10,0)
             , NVL(ALIQICMS1FONTETV10,0)
             , NVL(ALIQICMS2FONTETV10,0)
             , NVL(PERCBASEREDSTFONTETV10,0)
             , NVL(PAUTAFONTETV10,0)
          INTO v_ivafonte
             , v_aliqicms1fonte
             , v_aliqicms2fonte
             , v_percbaseredstfonte
             , n_pautafonte
          FROM PCTRIBUT 
       WHERE (CODST = pio_nCodSt);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          po_vMensagem := 'Não foram encontrados dados para a Tributação TV10: ' || NVL(pio_nCodSt,0);
        RAISE e_tratado;
      END;
    END IF;
    
    -- Tributação diferenciada para Pedido de Avaria
    IF (pi_vPedidoAvaria = 'S')              AND 
       (vUSARABAPERDASTFONTEPEDAVARIA = 'S') AND
       (NVL(pi_nCondVenda,0) <> 10)          THEN -- DDMEDICA-5115
      vUSAREDICMNORMVENDASTFONTE := 'N'; -->> Não usa a Redução da Aba Venda
      v_ivafonte                 := NVL(v_iva_mc,0);
      v_aliqicms1fonte           := NVL(v_aliqicms1_mc,0);
      v_aliqicms2fonte           := NVL(v_aliqicms2_mc,0);
      v_percbaseredstfonte       := NVL(v_percbaseredst_mc,0);
      n_pautafonte               := NVL(v_pauta_mc,0);
    END IF;
   
 /**********************************************************************
  Chama Procedimento para Obter os valores para Customização 
  da Base ST com SUFRAMA/Redução PISCOFINS e DESONERACAO - DDMEDICA-7594
  **********************************************************************/
  P_OBTER_VALORES_BENEF_FISCAIS(pi_vCodFilial,
                                pi_vCodFilial, -->> Não tenho a Filial NF na Procedure
                                pi_nCodCli,
                                pi_nCodProd,
                                pio_nCodSt,
                                v_numcasasdecvenda,
                                v_tipocalcsulframa,
                                v_perdescicmisencao,
                                v_aplicadescisencaomed,
                                ROUND(pi_vPVenda,v_numcasasdecvenda), -->> Deve ser usado o Preço com Arredondamento
                                0, -->> Aqui não irei atualizar o preço de tabela
                                0, -->> Aqui não irei atualizar o preço base rca
                                pi_nQT,
                                vnVlDescReducaoPis,
                                vnPercDescReducaoPisAuxBF,
                                vnVlDescReducaoCofins,
                                vnPercDescReducaoCofinsAuxBF,
                                vnVlDescIcmIsencao,
                                vnPercDescIcmIsencaoAuxBF,
                                vnVlDescSuframa,
                                vnPercDescSuframaAuxBF,
                                vnPrecoLiqResultAuxBF,
                                vnPrecoTabResultAuxBF,
                                vnPrecoRcaResultAuxBF,
                                vvErrosBenefFiscais,
                                vvMsgErrosBenefFiscais,
                                'S'); -- DDVENDAS-37241
    IF (vvErrosBenefFiscais = 'S') THEN
      RAISE e_benef_fiscais;
    END IF;                            
    BEGIN
      SELECT NVL(PAUTA,0) PAUTA
        INTO v_pauta_pcpautaprodutuf
        FROM PCPAUTAPRODUTUF
       WHERE PCPAUTAPRODUTUF.UF = v_estent
         AND PCPAUTAPRODUTUF.CODPROD = pi_nCodProd;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_pauta_pcpautaprodutuf := 0;
    END;
    IF v_pauta_pcpautaprodutuf <> 0 THEN
      v_pauta_mc := v_pauta_pcpautaprodutuf;
      n_pautafonte := v_pauta_pcpautaprodutuf;
    END IF;
   /***********************************************************
    Chama Procedimento para Calcular a Base e Valor do ST Fonte
    ***********************************************************/
    P_OBTER_STFONTE(pi_nCodProd                  , -->> Código do Produto passado no Parâmetro
                    pi_nCondVenda                , -->> Tipo de Venda Passado no Parâmetro
                    pi_nPercVenda                , -->> Percentual de Venda passado no Parâmetro
                    v_iva                        ,
                    v_ivafonte                   , --> Variável local no parâmetro de Entrada e Saída
                    v_aliqicms1fonte             , --> Variável local no parâmetro de Entrada e Saída
                    v_aliqicms2fonte             , --> Variável local no parâmetro de Entrada e Saída
                    v_percbaseredstfonte         , --> Variável local no parâmetro de Entrada e Saída
                    v_percbaserednrpa            ,
                    v_percbaseredconsumidor      ,
                    v_utilizapercbaseredpf_trib  ,
                    v_tipocalcst                 ,
                    v_calcstpf                   ,
                    v_utilizapercbaseredpf_param ,
                    v_clientefontest             ,
                    v_calculast                  ,
                    v_ieent                      ,
                    v_tipofj                     ,
                    v_isentoicms                 ,
                    v_consumidorfinal            ,
                    v_utilizaiesimplificada      ,
                    v_tipoempresa                ,
                    v_consideraisentoscomopf     ,
                    pi_vPVenda                   , --> Preço de Venda passado no Parâmetro
                    pi_nValorIpi                 , --> Valor do IPI passado no Parâmetro
                    v_uffilial                   ,
                    v_estent                     ,
                    v_usavalorultentbasest       ,
                    v_valorultent                ,
                    v_usaivafontediferenciado    ,
                    v_ivafonte_cli               ,
                    v_AceitaPFContribuinte       ,
                    v_ALIQICMS1                  ,
                    v_ALIQICMS2                  ,
                    v_contribuinte               ,
                    v_numcasasdecvenda           ,
                    v_custonfsemst               ,
                    v_usavalorultentbasest2      ,
                    v_usapmcbasest               ,
                    v_precomaxconsum             ,
                    v_tipoclimed                 ,
                    v_isencaostorgaopub          ,
                    v_usabaseicmsreduzida        ,
                    v_usabcrultent               ,
                    n_basebcrultent              ,
                    n_stbcrultent                ,
                    v_calcstpautafarmaciapopular ,
                    n_pautafonte                 ,
                    v_farmaciapopular            ,
                    v_participafarmaciapopular   ,                                        
                    v_usaptabelabasest           ,
                    NVL(pi_nPTabela,pi_vPVenda)  , -->> Se a chamada ainda não tiver o PTabela, usar o PVenda
                    pi_vSomenteIVATribut         ,
                    v_usadescsimplesnac          ,
                    v_simplesnacional            ,
                    n_percredpvendasimplesnac    ,
                    v_tipomerc                   ,
                    v_usarajusteprecocmed        ,
                    n_percajusteprecocmed        ,
                    v_usaregimeespisenstfonte    ,
                    v_regimeespisenstfonte       ,
                    v_medretirarstbnfestadual    ,
                    pi_vItemBonific              ,
                    pi_nVlFreteOutrasDesp        ,
                    v_bnfnaocalculaicms          ,
                    vUSAREGSIMPLCARGATRIBSTFONTE ,
                    vREGSIMPLCARGATRIBSTFONTE    ,
                    nPERCREGSIMPLCARGATRIBSTFONTE,
                    vUSAREDUTORCAT49BASESTFONTE  ,
                    nPERCREDUTORCAT49BASESTFONTE ,
                    vUSACARGAMINIMADEFERIMSTFONTE,
                    nPERCARGAMINIMADEFERIMSTFONTE,
                    vUSAVLSTMAIORPERCMINPMC,
                    nPERVLSTMAIORPERCMINPMC,
                    po_nBaseStFonte              , -->> BASE ST FONTE QUE SERA RETORNADA PELA PROCEDURE
                    po_nValorStFonte             , -->> VALOR ST FONTE QUE SERA RETORNADA PELA PROCEDURE
                    po_vMensagem                 , -->> Mensagem de Erro de Retorno 
                    po_vRegimeEspIsenStFonte     , -->> Retorno indicando se tem Isenção ST Fonte
                    po_nAliqIcms1                ,
                    po_nAliqIcms2                ,
                    po_nIva                      , 
                    po_nPercBaseRedStFonte       ,
                    po_nPautaFonte               ,
                    po_vObservacaoStFonte        ,
                    vvCodFilialFaturamento       ,
                    po_vIndEscalaRelevante       ,
                    v_participafuncep            ,
                    v_utilizamotorcalculo        ,
                    v_formulapvenda              ,
                    v_peracrescimofuncep         ,
                    v_aliqicmsfecp               ,
                    v_codconfigfuncepmed         ,
                    po_nVLBASEFCPICMS            ,
                    po_nVLBASEFCPST              ,
                    po_nVLBCFCPSTRET             ,
                    po_nPERFCPSTRET              ,
                    po_nVLFCPSTRET               ,
                    po_nPERFCPSN                 ,
                    po_nVLFECP                   ,
                    po_nVLACRESCIMOFUNCEP        ,
                    po_nVLCREDFCPICMSSN          ,
                    po_nPERACRESCIMOFUNCEP       ,
                    po_nALIQICMSFECP             ,
                    po_nCODCONFIGFUNCEPMED       ,
                    vUSAREDICMNORMVENDASTFONTE   ,
                    vPERCBASERED                 ,
                    v_percipivenda               ,
                    v_usavlultentmediobasest     ,
                    n_percbasestrj               ,
                    n_vlultentmes                ,
                    pi_nValorNotaFiscal          ,
                    v_usaReducaoBasePmc          ,
                    v_pertetoredbasepmc          ,
                    v_isencaostfontebonificacao  ,
                    v_usapmpfbasest              ,
                    vnPmPf                       ,
                    v_agregapiscofinsst1         ,
                    v_agregasuframast1           ,
                    v_agregaicmsisencaost1       , 
                    v_vagregapiscofinsst2        ,
                    v_agregasuframast2           ,
                    v_agregaicmsisencaost2       ,
                    vnVlDescReducaoPis           ,
                    vnVlDescReducaoCofins        ,
                    vnVlDescIcmIsencao           ,
                    vnVlDescSuframa              ,
                    v_destacicmsstanterior       ,
                    po_nBCSTRETANTERIOR          ,
                    po_nVLICMSSUBSTITUTOANTERIOR ,
                    po_nVLICMSSTRETANTERIOR      ,
                    v_tipocalculognre            ,
                    po_nSTCLIENTEGNRE            ,
                    po_nPMPF                     ,
                    v_desvincularFecpSTFuncepICMS,
				    v_utilizaCustoContBaseST   ,
				    vnFatorAjusteCustoCont     ,
				    v_ncustocont		  
                    );
  
    -- Se ocorreram erros na Função
    IF (TRIM(po_vMensagem) IS NOT NULL) THEN
      RAISE e_tratado;
    END IF;                                         
                                                             
  EXCEPTION
    WHEN e_tratado THEN
      -- Sem ST
      po_nBaseStFonte  := 0;
      po_nValorStFonte := 0;
    WHEN e_benef_fiscais THEN
      -- Sem ST
      po_nBaseStFonte  := 0;
      po_nValorStFonte := 0;
      po_vMensagem     := 'Erro Cálculo ST Fonte: ' || SUBSTR(vvMsgErrosBenefFiscais,1,240);
    WHEN OTHERS THEN  
      -- Sem ST
      po_nBaseStFonte  := 0;
      po_nValorStFonte := 0;
      po_vMensagem     := 'Erro Cálculo ST Fonte: ' || SUBSTR('Erro: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ' >> ' || SQLERRM,1,240);
  END P_OBTEM_STFONTE_42;

  /*******************************************************************************
   Nome         : P_RECALCULAR_STFONTE
   Descricão    : Procedimento para Recalcular o ST Fonte de um Pedido
   Observação   : O COMMIT deverá ser na procedure chamadora
   Parâmetros   : Entrada
                  pi_nNumPed                  = Número do Pedido
                  pi_vTipoChamada             = Determina o tipo de chamada da função 
                                                'F' - Chamado do Faturamento para Cálculo do PEPS
                                                'L' - Chamado do Cálculo do ST Especial
                                                      de Operador Logísitco - HIS.01858.2015                                          
                                                'P' - Chamado do Faturamento para recalcular 
                                                      o Preço de Tabela pelo Preço Fábrica
                                                'V' - Chamado do Faturamento para recalcular 
                                                      o Preço de Tabela pelo Preço Venda - HIS.05093.2017
                                                'B' - Recálculo dos Itens Bonificados
                  pi_vCalculaDesoneracaoLicit = Se calcula a desoneração da Licitação
                  pi_vAplicFatConvPedidoVenda = Parâmetro de Licitação
                  Saída
                  po_vOcorreramErros       = Se ocorreram Erros
                  pi_vvMsgErros            = Mensagem de Erros
   Alteracão    : Anderson Silva - 14/04/2012 - Criação da Procedure
   Alteração    : Rubens Junior  - 24/04/2015 - HIS.00679.2015 - ST PEPS
   Alteração    : Anderson Silva - 25/04/2015 - HIS.00679.2015 - ST PEPS 
                                                Ajuste Geração NUMSEQ
   Alteração    : Anderson Silva - 11/05/2015 - Não chamar a Package Faturamento para calcular CMV
   Alteração    : Anderson Silva - 01/09/2015 - Recalcular o Repasse
   Alteração    : Anderson Silva - 26/04/2016 - HIS.00558.2016 - Preço Fábrica no XML (precofabricabrutonfe)
   Alteração    : Anderson Silva - 30/03/2017 - 6803.037246.2017 - Desoneração Licitação
   Alteração    : Anderson Silva - 08/06/2017 - HIS.01838.2017 - MODALIDADE DE DETERMINAÇÃO DA BASE DE CÁLCULO DO ICMS ST
   Alteração    : Anderson Silva - 14/09/2017 - HIS.03371.2017 - Escala Relevante e não Relevante
   Alteração    : Anderson Silva - 09/11/2017 - HIS.04200.2017 - ST FUNCEP
   Alteração    : Anderson Silva - 11/01/2018 - HIS.04200.2017 - PCTRIBUT.CODCONFIGFUNCEPMED
   Alteração    : Anderson Silva - 22/05/2018 - MED-1096 - Cross Docking
   Alteracão    : Anderson Silva - 16/06/2018 - HIS.05093.2017 - Regra para Aplicar no Preço de Tabela o Preço de Venda
   Alteração    : Anderson Silva - 12/06/2018 - 5666.044130.2018 - Rebaixa CMV
   Alteração    : Anderson Silva - 31/01/2019 - MED-900 - Arredondar Preços
   Alteração    : Anderson Silva - 27/03/2019 - MED-2373 - Origem Custo Filial Retira
   Alteração    : Anderson Silva - 17/05/2019 - MED-2521 - Isenção ST Bonificação
   Alteração    : Anderson Silva - 24/01/2019 - DDMEDICA-1953 - ST exclusivo para Avaria de Perda vinculado ao GERACP
  ********************************************************************************/    
  PROCEDURE P_RECALCULAR_STFONTE(pi_nNumPed                  IN  NUMBER,
                                 po_vOcorreramErros          OUT VARCHAR2,
                                 pi_vvMsgErros               OUT VARCHAR2,
                                 pi_vTipoChamada             IN  VARCHAR2 DEFAULT 'O',
                                 pi_vCalculaDesoneracaoLicit IN  VARCHAR2 DEFAULT 'N',
                                 pi_vAplicFatConvPedidoVenda IN  VARCHAR2 DEFAULT NULL)                                 
  IS

    -- Parâmetros
    TYPE TRecParametros                IS RECORD(
         vnNumCasasDecVenda            PCCONSUM.NUMCASASDECVENDA%TYPE,
         vsAbaterImpostosComissaoRca   PCCONSUM.ABATERIMPOSTOSCOMISSAORCA%TYPE,
         vsAplicarIndiceCmv            PCCONSUM.APLICARINDICECMV%TYPE,
         vsIncluirComissaoSugPvendaCmv PCCONSUM.INCLUIRCOMISSAOSUGPVENDACMV%TYPE,
         vnTxVenda                     PCCONSUM.TXVENDA%TYPE,
         vvincluircomissaocmvvenda     PCCONSUM.INCLUIRCOMISSAOCMVVENDA%TYPE);
    vrParametros                       TRecParametros;
    -- Parâmetros por Filial
    TYPE TRecParametrosFilial          IS RECORD(
         vvTipoAplicRepasseFilial      PCPARAMFILIAL.VALOR%TYPE,
         vvOrigemCustoFilialRetira     PCFILIAL.ORIGEMCUSTOFILIALRETIRA%TYPE);
    vrParametrosFilial                 TRecParametrosFilial;  
    -- Dados da Região
    TYPE TRecDadosRegiao               IS RECORD(
         vnPerFreteTerceiros           PCREGIAO.PERFRETETERCEIROS%TYPE,
         vnPerFreteEspecial            PCREGIAO.PERFRETEESPECIAL%TYPE,
         vvRegiaoZfm                   PCREGIAO.REGIAOZFM%TYPE);
    vrDadosRegiao                      TRecDadosRegiao;
    -- Dados do Cliente
    TYPE TRecDadosCliente              IS RECORD(
         vvRepasse                     PCCLIENT.REPASSE%TYPE);
    vrDadosCliente                     TRecDadosCliente;
    -- Dados dos Itens do Pedido 
    vnPrecoLiqOriginal                 PCPEDI.PVENDA%TYPE;
    vnPrecoTabOriginal                 PCPEDI.PVENDA%TYPE;
    vnPrecoBaseRcaOriginal             PCPEDI.PVENDA%TYPE;
    vnBaseicst                         PCPEDI.BASEICST%TYPE;
    vnSt                               PCPEDI.ST%TYPE;
    vvMsgRetObterStFonte               VARCHAR2(2000);
    vvRegimeEspIsenStFonte             PCPEDI.REGIMEESPISENSTFONTE%TYPE;
    vnAliqIcms1                        PCTRIBUT.ALIQICMS1%TYPE;
    vnAliqIcms2                        PCTRIBUT.ALIQICMS2%TYPE;
    vnIva                              PCTRIBUT.IVA%TYPE;
    vnPercBaseRedStFonte               PCPEDI.PERCBASEREDSTFONTE%TYPE;
    vvmedcalcularstpelopeps            VARCHAR2(1);
    vnqtregistropepstemp               NUMERIC;
    vnqtregistroatupeps                NUMERIC;
    vnVlRepasse                        PCPEDI.VLREPASSE%TYPE;
    vnVlOutros                         PCPEDI.VLOUTROS%TYPE;
    vnPOriginal                        PCPEDI.PORIGINAL%TYPE;
    -- Dados dos Itens do Funcep - HIS.04200.2017
    TYPE TRecDadosFuncep               IS RECORD(
         nVLBASEFCPICMS                PCPEDI.VLBASEFCPICMS%TYPE,      -- HIS.04200.2017
         nVLBASEFCPST                  PCPEDI.VLBASEFCPST%TYPE,        -- HIS.04200.2017
         nVLBCFCPSTRET                 PCPEDI.VLBCFCPSTRET%TYPE,       -- HIS.04200.2017
         nPERFCPSTRET                  PCPEDI.PERFCPSTRET%TYPE,        -- HIS.04200.2017
         nVLFCPSTRET                   PCPEDI.VLFCPSTRET%TYPE,         -- HIS.04200.2017
         nPERFCPSN                     PCPEDI.PERFCPSN%TYPE,           -- HIS.04200.2017
         nVLFECP                       PCPEDI.VLFECP%TYPE,             -- HIS.04200.2017
         nVLACRESCIMOFUNCEP            PCPEDI.VLACRESCIMOFUNCEP%TYPE,  -- HIS.04200.2017
         nPERACRESCIMOFUNCEP           PCPEDI.PERACRESCIMOFUNCEP%TYPE, -- HIS.04200.2017
         nALIQICMSFECP                 PCPEDI.ALIQICMSFECP%TYPE,       -- HIS.04200.2017
         nVLCREDFCPICMSSN              PCPEDI.VLCREDFCPICMSSN%TYPE,    -- HIS.04200.2017
         nCODCONFIGFUNCEPMED           PCPEDI.CODCONFIGFUNCEPMED%TYPE, -- HIS.04200.2017
         nVLDESCICMISENCAO             PCPEDI.VLDESCICMISENCAO%TYPE    -- DDMEDICA-3065
         );
    vrDadosFuncep                      TRecDadosFuncep;
    -- Dados Tributação
    TYPE TRecDadosTributacao           IS RECORD(
         vnPerDescCusto                PCTRIBUT.PERDESCCUSTO%TYPE,
         vnCodicmtab                   PCTRIBUT.CODICMTAB%TYPE,
         vnCodicmtabpf                 PCTRIBUT.CODICMTABPF%TYPE,
         vnPerDescRepasse              PCTRIBUT.PERDESCREPASSE%TYPE,
         vbcodicmtabpf_enulo           BOOLEAN,
         vnAliqIcmsFecp                PCTRIBUT.ALIQICMSFECP%TYPE, -- HIS.04200.2017
		 vsUTILIZAICMTABFlex           PCTRIBUT.UTILIZAICMTABFLEX%TYPE															  
         );
    vrDadosTributacao                  TRecDadosTributacao;
    -- Dados PCEST
    TYPE TRecDadosEstoque              IS RECORD(
         vnCustoFin                    PCEST.CUSTOFIN%TYPE,
         vncustoReal                   PCEST.CUSTOREAL%TYPE);
     vrDadosEstoque                    TRecDadosEstoque;
    -- Valores de Custo do Item
    TYPE TRecValoresCusto              IS RECORD(
         vnPerfretecmv                 PCPEDI.PERFRETECMV%TYPE,
         vnCustofinest                 PCPEDI.CUSTOFINEST%TYPE,
         vnTxvenda                     PCPEDI.TXVENDA%TYPE,
         vnPerdesccusto                PCPEDI.PERDESCCUSTO%TYPE,
         vnCodicmtab                   PCPEDI.CODICMTAB%TYPE,
         vnVlcustofin                  PCPEDI.VLCUSTOFIN%TYPE,
         vnVlcustoreal                 PCPEDI.VLCUSTOREAL%TYPE,
         vnVldesccustocmv              PCPEDI.VLDESCCUSTOCMV%TYPE);
    vrValoresCusto                     TRecValoresCusto;    
    -- Totais do Pedido
    vnVlAtend                          NUMBER;
    vnVlTotal                          NUMBER;
    vnVlTabela                         NUMBER;
    vnVlCustoFin                       NUMBER; -- 5666.044130.2018
    -- Exceções
    e_CalcularStFonte                  EXCEPTION;
    
    -- Array de Itens do Pedido
    TYPE TRecItensPedido               IS RECORD(
         CODPROD                       PCPEDI.CODPROD%TYPE,
         NUMSEQ                        PCPEDI.NUMSEQ%TYPE,
         QT                            PCPEDI.QT%TYPE,
         PTABELA                       PCPEDI.PTABELA%TYPE,
         PVENDA                        PCPEDI.PVENDA%TYPE,
         PBASERCA                      PCPEDI.PBASERCA%TYPE,
         CODST                         PCPEDI.CODST%TYPE,
         ST                            PCPEDI.ST%TYPE,
         VLIPI                         PCPEDI.VLIPI%TYPE,
         PRECOMAXCONSUM                PCPEDI.PRECOMAXCONSUM%TYPE,
         PERCOM                        PCPEDI.PERCOM%TYPE,
         FRETEESPECIAL                 PCPRODUT.FRETEESPECIAL%TYPE,
         TIPOMERC                      PCPRODUT.TIPOMERC%TYPE,
         VLREPASSE                     PCPEDI.VLREPASSE%TYPE,
         CUSTOREP                      PCPRODUT.CUSTOREP%TYPE,
         CUSTOREPZFM                   PCPRODUT.CUSTOREPZFM%TYPE,
         PORIGINAL                     PCPEDI.PORIGINAL%TYPE,
         CODEDITAL                     PCPEDC.CODEDITAL%TYPE,
         LOTECONTRATO                  PCPEDI.LOTECONTRATO%TYPE,
         NUMSEQITEMCONTRATO            PCPEDI.NUMSEQITEMCONTRATO%TYPE,
         QTPEDLICIT                    PCPEDI.QTPEDLICIT%TYPE,
         TIPOCONVERSAOPEDLICIT         PCPEDI.TIPOCONVERSAOPEDLICIT%TYPE,
         UNIDADECONVERSAOPEDLICIT      PCPEDI.UNIDADECONVERSAOPEDLICIT%TYPE,
         FATORCONVERSAOPEDLICIT        PCPEDI.FATORCONVERSAOPEDLICIT%TYPE,
         QTDEDOACAOPEDLICIT            PCPEDI.QTDEDOACAOPEDLICIT%TYPE,
         VLVERBACMV                    PCPEDI.VLVERBACMV%TYPE,         -- 5666.044130.2018       
         VLBASEFCPICMS                 PCPEDI.VLBASEFCPICMS%TYPE,      -- HIS.04200.2017
         VLBASEFCPST                   PCPEDI.VLBASEFCPST%TYPE,        -- HIS.04200.2017
         VLBCFCPSTRET                  PCPEDI.VLBCFCPSTRET%TYPE,       -- HIS.04200.2017
         PERFCPSTRET                   PCPEDI.PERFCPSTRET%TYPE,        -- HIS.04200.2017
         VLFCPSTRET                    PCPEDI.VLFCPSTRET%TYPE,         -- HIS.04200.2017
         PERFCPSN                      PCPEDI.PERFCPSN%TYPE,           -- HIS.04200.2017
         VLFECP                        PCPEDI.VLFECP%TYPE,             -- HIS.04200.2017
         VLACRESCIMOFUNCEP             PCPEDI.VLACRESCIMOFUNCEP%TYPE,  -- HIS.04200.2017
         PERACRESCIMOFUNCEP            PCPEDI.PERACRESCIMOFUNCEP%TYPE, -- HIS.04200.2017
         ALIQICMSFECP                  PCPEDI.ALIQICMSFECP%TYPE,       -- HIS.04200.2017
         VLCREDFCPICMSSN               PCPEDI.VLCREDFCPICMSSN%TYPE,    -- HIS.04200.2017
         CODCONFIGFUNCEPMED            PCPEDI.CODCONFIGFUNCEPMED%TYPE,
         VLDESCNEG                     PCPEDI.VLDESCNEG%TYPE,          -- HIS.05093.2017
         TIPODESCNEG                   PCPEDI.TIPODESCNEG%TYPE,        -- HIS.05093.2017
         CODFILIALRETIRA               PCPEDI.CODFILIALRETIRA%TYPE,
         BONIFIC                       PCPEDI.BONIFIC%TYPE,            -- MED-2521
         VLDESCICMISENCAO              PCPEDI.VLDESCICMISENCAO%TYPE,   -- DDMEDICA-3065
         VLDESCSUFRAMA                 PCPEDI.VLDESCSUFRAMA%TYPE,      -- DDMEDICA-7584
         VLDESCPISSUFRAMA              PCPEDI.VLDESCPISSUFRAMA%TYPE,   -- DDMEDICA-7584
         VLDESCREDUCAOPIS              PCPEDI.VLDESCREDUCAOPIS%TYPE,   -- DDMEDICA-7584
         VLDESCREDUCAOCOFINS           PCPEDI.VLDESCREDUCAOCOFINS%TYPE,-- DDMEDICA-7584
         BCSTRETANTERIOR               PCPEDI.BCSTRETANTERIOR%TYPE,          -- DDMEDICA-7697
         VLICMSSUBSTITUTOANTERIOR      PCPEDI.VLICMSSUBSTITUTOANTERIOR%TYPE, -- DDMEDICA-7697
         VLICMSSTRETANTERIOR           PCPEDI.VLICMSSTRETANTERIOR%TYPE,      -- DDMEDICA-7697
         STCLIENTEGNRE                 PCPEDI.STCLIENTEGNRE%TYPE,            -- DDMEDICA-7697
         VLDESCCMVPROMOCAOMED          PCPEDI.VLDESCCMVPROMOCAOMED%TYPE,      -- DDMEDICA-7697
		 CODICMTAB                     PCPEDI.CODICMTAB%TYPE													
         );     

    vrItensPedido                      TRecItensPedido;  
    TYPE TTvItensPedido                IS TABLE OF TRecItensPedido INDEX BY BINARY_INTEGER;
    vtItensPedido                      TTvItensPedido;
    viIdxItePed                        INTEGER;      
  
    vvincluircomissaocmvvenda          PCCONSUM.INCLUIRCOMISSAOCMVVENDA%TYPE;
    vnPerComCmv                        PCPEDI.PERCOM%TYPE;
    
    vnAuxPrecoFabrica                  PCPEDI.PORIGINAL%TYPE;
    vnAuxPrecoMaxConsum                PCPEDI.PRECOMAXCONSUM%TYPE;
    vvMsgPmcUf                         VARCHAR2(250);
  
    vnvlbnftv1                         NUMBER;
    
    -- Calculo da Desoneração da Licitação - 6803.037246.2017
    nVLDESCICMISENCAO                  PCPEDI.VLDESCICMISENCAO%TYPE;
    nPERDESCISENTOICMS                 PCPEDI.PERDESCISENTOICMS%TYPE;
    TYPE TRecDadosItemEdital           IS RECORD(
         vvUsarDesoneraIcm             VARCHAR2(200),
         vnPercDesoneraIcm             NUMBER);
    vrDadosItemEdital                  TRecDadosItemEdital;
    vrLimpaDadosItemEdital             TRecDadosItemEdital;
    vvSqlDesoneracaoIcms               VARCHAR2(2000);       
    -- Doação da Licitação - 6803.037246.2017
    TYPE TRecDadosDoacao               IS RECORD(
         vnQtdeLotes                   NUMBER,
         vnPrimeiroNumSeqProduto       NUMBER,
         edtQtdeVendida_EMPENHO        NUMBER,
         vnQtdeTotalProduto            NUMBER,
         vAPLICFATCONVPEDIDOVENDA      VARCHAR2(200),
         edtFATORCONVERSAO             NUMBER, 
         vnQtdeEmpenhoUnidadeProduto   NUMBER, 
         vdQtdeFinal                   NUMBER,
         vdQtdeFinalOriginal           NUMBER,
         vdQtdeDif                     NUMBER,
         edtValorDesc                  NUMBER,
         edtValorUnitDesc              NUMBER,
         dPrecoTabela                  NUMBER);
    vrDadosDoacao                      TRecDadosDoacao;     
    vrLimpaDadosDoacao                 TRecDadosDoacao;     
    
    -- HIS.01838.2017
    vnPautaFonte                       PCPEDI.PAUTA%TYPE;
    vvObservacaoStFonte                PCPEDI.OBSERVACAOSTFONTE%TYPE;
    -- HIS.03371.2017
    vvIndEscalaRelevante               PCPEDI.INDESCALARELEVANTE%TYPE;
    vvCnpjFabricante                   PCPEDI.CNPJFABRICANTE%TYPE;
    vvFabricante                       PCPEDI.FABRICANTE%TYPE;
    -- HIS.05093.2017
    vnNumRegiao                        PCPEDC.NUMREGIAO%TYPE;
    -- DDMEDICA-1691 - PMPF de Medicamentos
    vnPmPfMedicamento                  PCTABMEDABCFARMA.PMPF%TYPE;
    -- Recálculo Parcial do Pedido - DDMEDICA-6666
    vbRecalcProduto                    BOOLEAN; 
    -- DDMEDICA-7584 - Somatório dos valores unitários dos benefícios fiscais
    vnVlSomaDescUnitBenefFiscais       NUMBER;
    -- DDVENDAS-33718 - UF de Entrega do Cliente
    vvEstEnt                           PCCLIENT.ESTENT%TYPE;

    -- DDMEDICA-7697
    vnStClienteGnre                    PCPEDI.STCLIENTEGNRE%TYPE;
    vnStClienteGnreFonte               PCPEDI.STCLIENTEGNRE%TYPE;
    TYPE TRecDadosStAntecip            IS RECORD(
         nBCSTRETANTERIOR              PCPEDI.BCSTRETANTERIOR%TYPE,
         nVLICMSSUBSTITUTOANTERIOR     PCPEDI.VLICMSSUBSTITUTOANTERIOR%TYPE,
         nVLICMSSTRETANTERIOR          PCPEDI.VLICMSSTRETANTERIOR%TYPE);
    vrDadosStAntecip                   TRecDadosStAntecip;
    vvClienteFonteSt                   PCCLIENT.CLIENTEFONTEST%TYPE;
    
    -- DDVENDAS-33718
    vUTILIZATRIBENDENT                 PCPARAMFILIAL.VALOR%TYPE;
         
    --------------------------------------------
    -- Procedimento para cálculo do CMV
    --------------------------------------------
    PROCEDURE p_calcularcmv_med(p_abaterimpostoscomissaorca   IN VARCHAR2,
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
                                p_pvenda                      IN NUMBER,
                                p_percom                      IN NUMBER,
                                p_st                          IN NUMBER,
                                p_vlipi                       IN NUMBER,
                                p_vliss                       IN NUMBER,
                                p_contribuinte                IN VARCHAR2,
                                p_vldesccmvpromocaomed        IN NUMBER,
                                p_vlicmsstretanterior         IN NUMBER,
                                p_perfretecmv                 OUT NUMBER,
                                p_custofinest                 OUT NUMBER,
                                p_txvenda_item                OUT NUMBER,
                                p_perdesccusto_item           OUT NUMBER,
                                p_codicmtab_item              OUT NUMBER,
                                p_vlcustoreal                 OUT NUMBER,
                                p_vlcustofin                  OUT NUMBER,
                                p_vldesccustocmv              OUT NUMBER) IS
      vnbasecalccomissao NUMBER := 0;
    BEGIN
      --Dados para cálculo do CMV
      p_perfretecmv := p_perfreteterceiros;
  
      IF p_freteespecial = 'S' THEN
        p_perfretecmv := p_perfreteespecial;
      END IF;
  
      p_custofinest       := p_custofin;
      p_txvenda_item      := NVL(p_txvenda, 0);
      p_perdesccusto_item := NVL(p_perdesccusto, 0);
      p_codicmtab_item    := NVL(p_codicmtab, 0);
  
      IF (p_tipofj = 'F') AND (p_utilizaiesimplificada = 'N') AND
         ((UPPER(TRIM(p_ieent)) = 'ISENTO') OR
         (UPPER(TRIM(p_ieent)) = 'ISENTA')) AND (p_codicmtabpf IS NOT NULL) THEN
        p_codicmtab_item := NVL(p_codicmtabpf, 0);
      END IF;
  
      --Tarefa 45842: Pessoa Fisica com Inscricao Estadual e marcada como Contribuinte
      --Sera tratada como pessoa juridica
      IF (p_tipofj = 'F') AND (UPPER(TRIM(p_ieent)) <> 'ISENTO') AND
         (UPPER(TRIM(p_ieent)) <> 'ISENTA') AND (UPPER(TRIM(p_ieent)) <> '') AND
         (p_contribuinte = 'S') THEN
        p_codicmtab_item := NVL(p_codicmtab, 0);
      END IF;
  
      --Tarefa 25188
      vnbasecalccomissao := p_pvenda;
  
      IF p_abaterimpostoscomissaorca = 'S' THEN
        vnbasecalccomissao := p_pvenda - NVL(p_st, 0) - NVL(p_vlipi, 0) -
                              NVL(p_vliss, 0);
      END IF;
  
      --tarefas 43617 e 44750
      IF p_aplicarindicecmv = 'S' THEN
        p_vlcustoreal := (p_custoreal -
                         (p_custoreal * NVL(p_perdesccusto_item, 0) / 100) +
                         (p_pvenda * p_txvenda_item / 100) +
                         (vnbasecalccomissao * NVL(p_percom, 0) / 100) +
                         (p_pvenda * NVL(p_perfretecmv, 0) / 100) +
                         ((p_pvenda - NVL(p_st, 0) - NVL(p_vlipi, 0) -
                         NVL(p_vliss, 0)) --Tarefa 43617
                         * (p_codicmtab_item / 100)) + NVL(p_st, 0) +
                         NVL(p_vlipi, 0) + NVL(p_vliss, 0));
        p_vlcustofin  := (p_custofinest -
                         (p_custofinest * NVL(p_perdesccusto_item, 0) / 100) +
                         (p_pvenda * p_txvenda_item / 100) +
                         (vnbasecalccomissao * NVL(p_percom, 0) / 100) +
                         (p_pvenda * NVL(p_perfretecmv, 0) / 100) +
                         ((p_pvenda - NVL(p_st, 0) - NVL(p_vlipi, 0) -
                         NVL(p_vliss, 0)) --Tarefa 43617
                         * (p_codicmtab_item / 100)) + NVL(p_st, 0) +
                         NVL(p_vlipi, 0) + NVL(p_vliss, 0));
      ELSE
        p_vlcustoreal := (p_custoreal -
                         (p_custoreal * NVL(p_perdesccusto_item, 0) / 100) +
                         (p_pvenda * p_txvenda_item / 100) +
                         (vnbasecalccomissao * NVL(p_percom, 0) / 100) +
                         (p_pvenda * NVL(p_perfretecmv, 0) / 100) +
                         ((p_pvenda - NVL(p_st, 0) - NVL(p_vlipi, 0) -
                         NVL(p_vliss, 0)) * (p_codicmtab_item / 100)) + p_st +
                         NVL(p_vlipi, 0) + NVL(p_vliss, 0));
        p_vlcustofin  := (p_custofinest -
                         (p_custofinest * NVL(p_perdesccusto_item, 0) / 100) +
                         (p_pvenda * p_txvenda_item / 100) +
                         (vnbasecalccomissao * NVL(p_percom, 0) / 100) +
                         (p_pvenda * NVL(p_perfretecmv, 0) / 100) +
                         ((p_pvenda - NVL(p_st, 0) - NVL(p_vlipi, 0) -
                         NVL(p_vliss, 0)) * (p_codicmtab_item / 100)) + p_st +
                         NVL(p_vlipi, 0) + NVL(p_vliss, 0));
      END IF;
  
      -- tarefa 56190
      IF NVL(p_incluircomissaosugpvendacmv, 'S') = 'N' THEN
        p_vlcustoreal := p_vlcustoreal -
                         (vnbasecalccomissao * NVL(p_percom, 0) / 100);
        p_vlcustofin  := p_vlcustofin -
                         (vnbasecalccomissao * NVL(p_percom, 0) / 100);
      END IF;
  
      -- Valor do Desconto no Custo Financeiro
      p_vldesccustocmv := (ROUND(((NVL(p_custofinest, 0) *
                                 NVL(p_perdesccusto_item, 0) / 100) * 100))) / 100;

      -- Verba de Fornecedor da Promoção para Rebaixa CMV - DDMEDICA-7697
      IF (NVL(p_vldesccmvpromocaomed,0) <> 0) THEN
        p_vlcustoreal := (p_vlcustoreal - NVL(p_vldesccmvpromocaomed,0));
        p_vlcustofin  := (p_vlcustofin  - NVL(p_vldesccmvpromocaomed,0));
      END IF;

    END p_calcularcmv_med;
  
  BEGIN
  
    ----------------------
    -- Inicializa Retornos
    ----------------------
    po_vOcorreramErros := 'N';
    pi_vvMsgErros      := NULL;
    
    -- Parâmetros
    SELECT NVL(PCCONSUM.NUMCASASDECVENDA,2) -- MED-900
         , PCCONSUM.ABATERIMPOSTOSCOMISSAORCA
         , PCCONSUM.APLICARINDICECMV
         , PCCONSUM.ABATERIMPOSTOSCOMISSAORCA
         , PCCONSUM.INCLUIRCOMISSAOSUGPVENDACMV
         , PCCONSUM.TXVENDA
         , NVL(INCLUIRCOMISSAOCMVVENDA,'S')
      INTO vrParametros.vnNumCasasDecVenda     
         , vrParametros.vsAbaterImpostosComissaoRca
         , vrParametros.vsAplicarIndiceCmv
         , vrParametros.vsAbaterImpostosComissaOrca
         , vrParametros.vsIncluirComissaoSugPvendaCmv
         , vrParametros.vnTxVenda
         , vrParametros.vvincluircomissaocmvvenda
      FROM PCCONSUM
     WHERE (ROWNUM = 1);
                                                                                                   
    ------------------
    -- Dados do Pedido
    ------------------
    FOR vc_CabecalhoPedido IN (SELECT PCPEDC.NUMPED
                                    , PCPEDC.CODFILIAL
                                    , PCPEDC.CODFILIALNF
                                    , PCPEDC.CODCLI
                                    , PCPEDC.NUMREGIAO
                                    , PCPEDC.CONDVENDA                                 
                                    , PCPEDC.VLDESCONTO
                                    , PCPEDC.VLOUTRASDESP
                                    , PCPEDC.VLFRETE
                                    , PCCLIENT.TIPOFJ
                                    , PCCLIENT.UTILIZAIESIMPLIFICADA
                                    , PCCLIENT.CONSUMIDORFINAL     
                                    , PCCLIENT.IEENT   
                                    , PCCLIENT.CONTRIBUINTE
                                    , PCCLIENT.ESTENT
                                    , PCPEDC.CODEDITAL
                                    , PCCLIENT.PARTICIPAFUNCEP -- HIS.04200.2017
                                    , PCPEDC.NUMTRANSENTCROSSDOCK -- MED-1096 - Custo do Cross Docking
                                    , CASE WHEN (NVL(PCPEDC.PEDIDOAVARIA,'N') = 'S') AND
                                                (NVL(PCPEDC.GERACP,'N')       = 'S') AND
                                                (NVL(PCPEDC.CONDVENDA,0)     <>  10) THEN -- DDMEDICA-5115
                                        'S'
                                      ELSE
                                        'N'
                                      END TRIBUTPEDIDOAVARIAPERDA
                                    , PCPEDC.CODENDENTCLI -- DDVENDAS-33718
                                 FROM PCPEDC
                                    , PCCLIENT
                                WHERE (PCCLIENT.CODCLI = PCPEDC.CODCLI)
                                  AND (PCPEDC.NUMPED   = pi_nNumPed)) LOOP
                               
      -- Região - HIS.05093.2017
      vnNumRegiao := vc_CabecalhoPedido.NUMREGIAO;
      -- Se não gravou a Região no Pedido - HIS.05093.2017
      IF (NVL(vnNumRegiao,0) = 0) THEN
        -- Pesquisa Região do Cliente por Filial
        BEGIN
          SELECT NUMREGIAO
            INTO vnNumRegiao
            FROM PCTABPRCLI
           WHERE (CODCLI      = vc_CabecalhoPedido.CODCLI)
             AND (CODFILIALNF = NVL(vc_CabecalhoPedido.CODFILIALNF,vc_CabecalhoPedido.CODFILIAL)); -- HIS.03371.2017
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vnNumRegiao := NULL;
        END;    
        -- Se não achou Regiao do Cliente por Filial
        IF (vnNumRegiao IS NULL) THEN
          -- Pesquisa Região da Praça
          BEGIN
            SELECT PCPRACA.NUMREGIAO
              INTO vnNumRegiao
              FROM PCPRACA
                 , PCCLIENT
             WHERE (PCCLIENT.CODPRACA = PCPRACA.CODPRACA)
               AND (PCCLIENT.CODCLI   = vc_CabecalhoPedido.CODCLI);
          EXCEPTION
           WHEN NO_DATA_FOUND THEN
              vnNumRegiao := NULL;
          END;
        END IF;    
      END IF; 
      
      -- DDVENDAS-33718 - UF de Entrega do Cliente
      proc_pcparamfilial(vc_CabecalhoPedido.CODFILIAL,
                         'UTILIZATRIBENDENT',
                         'N',
                          vUTILIZATRIBENDENT);
      vvEstEnt := F_DEFINIRUFDESTINOPEDIDO(vc_CabecalhoPedido.CODCLI,
                                           vUTILIZATRIBENDENT,
                                           vc_CabecalhoPedido.CODENDENTCLI,
                                           vc_CabecalhoPedido.ESTENT);
                               
      -- Pesquisa Dados da Região
      BEGIN
        SELECT PCREGIAO.PERFRETETERCEIROS
             , PCREGIAO.PERFRETEESPECIAL
             , PCREGIAO.REGIAOZFM
          INTO vrDadosRegiao.vnPerFreteTerceiros
             , vrDadosRegiao.vnPerFreteEspecial
             , vrDadosRegiao.vvRegiaoZfm
          FROM PCREGIAO
         WHERE (PCREGIAO.NUMREGIAO = vnNumRegiao); -- HIS.05093.2017 - Região do Pedido ou do Cliente
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vrDadosRegiao.vnPerFreteTerceiros := 0;
          vrDadosRegiao.vnPerFreteEspecial  := 0;
          vrDadosRegiao.vvRegiaoZfm         := 0;
      END;            
      
      -- Buscando Parâmetros da Filial
      BEGIN
        SELECT NVL(VALOR,'N') VALOR
          INTO vvmedcalcularstpelopeps
          FROM PCPARAMFILIAL
         WHERE (CODFILIAL = vc_CabecalhoPedido.CODFILIAL)
           AND (NOME      = 'MEDCALCULARSTPELOPEPS');
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
           vvmedcalcularstpelopeps := 'N';
      END;  
      --    
      BEGIN
        SELECT NVL(VALOR,'N') VALOR
          INTO vrParametrosFilial.vvTipoAplicRepasseFilial
          FROM PCPARAMFILIAL
         WHERE (CODFILIAL = vc_CabecalhoPedido.CODFILIAL)
           AND (NOME      = 'TIPOAPLICREPASSEFILIAL');
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
           vrParametrosFilial.vvTipoAplicRepasseFilial := 'AB'; -->> Default pelo Bruto
      END;  
      --
      BEGIN
        SELECT PCFILIAL.ORIGEMCUSTOFILIALRETIRA
          INTO vrParametrosFilial.vvOrigemCustoFilialRetira
          FROM PCFILIAL
         WHERE (CODIGO = vc_CabecalhoPedido.CODFILIAL);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vrParametrosFilial.vvOrigemCustoFilialRetira := NULL;
      END;
          
      -- Pesquisa Parâmetros de Tributação do Cliente por Filial
      BEGIN
        SELECT PCCLIENTFILIALMED.REPASSE      
          INTO vrDadosCliente.vvRepasse
          FROM PCCLIENTFILIALMED
         WHERE (PCCLIENTFILIALMED.CODCLI    = vc_CabecalhoPedido.CODCLI)
           AND (PCCLIENTFILIALMED.CODFILIAL = vc_CabecalhoPedido.CODFILIAL);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- Se não encontrar Parâmetros de Tributação do Cliente por Filial, ignora, mantendo os o Cliente
          BEGIN
            SELECT PCCLIENT.REPASSE      
              INTO vrDadosCliente.vvRepasse
              FROM PCCLIENT
             WHERE (PCCLIENT.CODCLI    = vc_CabecalhoPedido.CODCLI);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vrDadosCliente.vvRepasse := 'N';
          END;
      END;           
      
      ----------------------------
      -- Cursor de Itens do Pedido
      ----------------------------
      FOR vc_ItensPedido IN (SELECT PCPEDI.CODPROD
                                  , PCPEDI.NUMSEQ
                                  , PCPEDI.QT
                                  , PCPEDI.PTABELA
                                  , PCPEDI.PVENDA
                                  , PCPEDI.PBASERCA
                                  , PCPEDI.CODST
                                  , PCPEDI.ST
                                  , PCPEDI.VLIPI
                                  , PCPEDI.PRECOMAXCONSUM
                                  , PCPEDI.PERCOM
                                  , PCPRODUT.FRETEESPECIAL
                                  , PCPRODUT.TIPOMERC
                                  , PCPEDI.VLREPASSE
                                  , PCPRODUT.CUSTOREP
                                  , PCPRODUT.CUSTOREPZFM
                                  , PCPEDI.PORIGINAL
                                  , PCPEDI.CODEDITAL
                                  , PCPEDI.LOTECONTRATO
                                  , PCPEDI.NUMSEQITEMCONTRATO                                
                                  , PCPEDI.QTPEDLICIT
                                  , PCPEDI.TIPOCONVERSAOPEDLICIT
                                  , PCPEDI.UNIDADECONVERSAOPEDLICIT
                                  , PCPEDI.FATORCONVERSAOPEDLICIT
                                  , PCPEDI.QTDEDOACAOPEDLICIT
                                  , PCPEDI.VLVERBACMV         -- 5666.044130.2018
                                  , PCPEDI.VLBASEFCPICMS      -- HIS.04200.2017
                                  , PCPEDI.VLBASEFCPST        -- HIS.04200.2017
                                  , PCPEDI.VLBCFCPSTRET       -- HIS.04200.2017
                                  , PCPEDI.PERFCPSTRET        -- HIS.04200.2017
                                  , PCPEDI.VLFCPSTRET         -- HIS.04200.2017
                                  , PCPEDI.PERFCPSN           -- HIS.04200.2017
                                  , PCPEDI.VLFECP             -- HIS.04200.2017
                                  , PCPEDI.VLACRESCIMOFUNCEP  -- HIS.04200.2017
                                  , PCPEDI.PERACRESCIMOFUNCEP -- HIS.04200.2017
                                  , PCPEDI.ALIQICMSFECP       -- HIS.04200.2017
                                  , PCPEDI.VLCREDFCPICMSSN    -- HIS.04200.2017                                
                                  , PCPEDI.CODCONFIGFUNCEPMED
                                  , PCPEDI.VLDESCNEG          -- HIS.05093.2017
                                  , PCPEDI.TIPODESCNEG        -- HIS.05093.2017                                
                                  , PCPEDI.CODFILIALRETIRA
                                  , PCPEDI.BONIFIC            -- MED-2521
                                  , PCPEDI.VLDESCICMISENCAO   -- DDMEDICA-3065                                  
                                  , PCPEDI.VLDESCSUFRAMA      -- DDMEDICA-7584
                                  , PCPEDI.VLDESCPISSUFRAMA   -- DDMEDICA-7584
                                  , PCPEDI.VLDESCREDUCAOPIS   -- DDMEDICA-7584
                                  , PCPEDI.VLDESCREDUCAOCOFINS-- DDMEDICA-7584
                                  , PCPEDI.BCSTRETANTERIOR          -- DDMEDICA-7697
                                  , PCPEDI.VLICMSSUBSTITUTOANTERIOR -- DDMEDICA-7697
                                  , PCPEDI.VLICMSSTRETANTERIOR      -- DDMEDICA-7697
                                  , PCPEDI.STCLIENTEGNRE            -- DDMEDICA-7697
                                  , PCPEDI.VLDESCCMVPROMOCAOMED     -- DDMEDICA-7697
								  , PCPEDI.CODICMTAB
                               FROM PCPEDI
                                  , PCPRODUT
                              WHERE (PCPRODUT.CODPROD = PCPEDI.CODPROD)
                                AND (PCPEDI.NUMPED    = vc_CabecalhoPedido.NUMPED)
                              ORDER BY PCPEDI.NUMSEQ) LOOP

        -- Recálculo Parcial do Pedido - DDMEDICA-6666
        vbRecalcProduto := TRUE; 
        -- Somente Itens Bonificados                      
        IF (pi_vTipoChamada = 'B') THEN
          IF (NVL(vc_ItensPedido.BONIFIC,'N') <> 'F') THEN
            vbRecalcProduto := FALSE; 
          END IF;
        END IF;
                 
        -- Array de Itens do Pedido
        IF (vbRecalcProduto) THEN -- DDMEDICA-6666
          viIdxItePed := NVL(vtItensPedido.COUNT,0) + 1;
          vtItensPedido(viIdxItePed).CODPROD                  := vc_ItensPedido.CODPROD;
          vtItensPedido(viIdxItePed).NUMSEQ                   := vc_ItensPedido.NUMSEQ;
          vtItensPedido(viIdxItePed).QT                       := vc_ItensPedido.QT;                
          vtItensPedido(viIdxItePed).PTABELA                  := vc_ItensPedido.PTABELA;       
          vtItensPedido(viIdxItePed).PVENDA                   := vc_ItensPedido.PVENDA;       
          vtItensPedido(viIdxItePed).PBASERCA                 := vc_ItensPedido.PBASERCA;      
          vtItensPedido(viIdxItePed).CODST                    := vc_ItensPedido.CODST;         
          vtItensPedido(viIdxItePed).ST                       := vc_ItensPedido.ST;            
          vtItensPedido(viIdxItePed).VLIPI                    := vc_ItensPedido.VLIPI;         
          vtItensPedido(viIdxItePed).PRECOMAXCONSUM           := vc_ItensPedido.PRECOMAXCONSUM;
          vtItensPedido(viIdxItePed).PERCOM                   := vc_ItensPedido.PERCOM;        
          vtItensPedido(viIdxItePed).FRETEESPECIAL            := vc_ItensPedido.FRETEESPECIAL;
          vtItensPedido(viIdxItePed).TIPOMERC                 := vc_ItensPedido.TIPOMERC;
          vtItensPedido(viIdxItePed).VLREPASSE                := vc_ItensPedido.VLREPASSE;
          vtItensPedido(viIdxItePed).CUSTOREP                 := vc_ItensPedido.CUSTOREP;
          vtItensPedido(viIdxItePed).CUSTOREPZFM              := vc_ItensPedido.CUSTOREPZFM;
          vtItensPedido(viIdxItePed).PORIGINAL                := vc_ItensPedido.PORIGINAL;
          -- Campos Licitação - 6803.037246.2017
          vtItensPedido(viIdxItePed).CODEDITAL                := vc_ItensPedido.CODEDITAL;
          vtItensPedido(viIdxItePed).LOTECONTRATO             := vc_ItensPedido.LOTECONTRATO;
          vtItensPedido(viIdxItePed).NUMSEQITEMCONTRATO       := vc_ItensPedido.NUMSEQITEMCONTRATO;    
          vtItensPedido(viIdxItePed).QTPEDLICIT               := vc_ItensPedido.QTPEDLICIT;
          vtItensPedido(viIdxItePed).TIPOCONVERSAOPEDLICIT    := vc_ItensPedido.TIPOCONVERSAOPEDLICIT;
          vtItensPedido(viIdxItePed).UNIDADECONVERSAOPEDLICIT := vc_ItensPedido.UNIDADECONVERSAOPEDLICIT;
          vtItensPedido(viIdxItePed).FATORCONVERSAOPEDLICIT   := vc_ItensPedido.FATORCONVERSAOPEDLICIT;
          vtItensPedido(viIdxItePed).QTDEDOACAOPEDLICIT       := vc_ItensPedido.QTDEDOACAOPEDLICIT;      
          vtItensPedido(viIdxItePed).VLVERBACMV               := vc_ItensPedido.VLVERBACMV; -- 5666.044130.2018      
          vtItensPedido(viIdxItePed).VLBASEFCPICMS            := vc_ItensPedido.VLBASEFCPICMS;      -- HIS.04200.2017
          vtItensPedido(viIdxItePed).VLBASEFCPST              := vc_ItensPedido.VLBASEFCPST;        -- HIS.04200.2017
          vtItensPedido(viIdxItePed).VLBCFCPSTRET             := vc_ItensPedido.VLBCFCPSTRET;       -- HIS.04200.2017
          vtItensPedido(viIdxItePed).PERFCPSTRET              := vc_ItensPedido.PERFCPSTRET;        -- HIS.04200.2017
          vtItensPedido(viIdxItePed).VLFCPSTRET               := vc_ItensPedido.VLFCPSTRET;         -- HIS.04200.2017
          vtItensPedido(viIdxItePed).PERFCPSN                 := vc_ItensPedido.PERFCPSN;           -- HIS.04200.2017
          vtItensPedido(viIdxItePed).VLFECP                   := vc_ItensPedido.VLFECP;             -- HIS.04200.2017
          vtItensPedido(viIdxItePed).VLACRESCIMOFUNCEP        := vc_ItensPedido.VLACRESCIMOFUNCEP;  -- HIS.04200.2017
          vtItensPedido(viIdxItePed).PERACRESCIMOFUNCEP       := vc_ItensPedido.PERACRESCIMOFUNCEP; -- HIS.04200.2017
          vtItensPedido(viIdxItePed).ALIQICMSFECP             := vc_ItensPedido.ALIQICMSFECP;       -- HIS.04200.2017
          vtItensPedido(viIdxItePed).VLCREDFCPICMSSN          := vc_ItensPedido.VLCREDFCPICMSSN;    -- HIS.04200.2017                                
          vtItensPedido(viIdxItePed).CODCONFIGFUNCEPMED       := vc_ItensPedido.CODCONFIGFUNCEPMED;    -- HIS.04200.2017                                      
          vtItensPedido(viIdxItePed).VLDESCNEG                := vc_ItensPedido.VLDESCNEG;          -- HIS.05093.2017
          vtItensPedido(viIdxItePed).TIPODESCNEG              := vc_ItensPedido.TIPODESCNEG;        -- HIS.05093.2017                                
          vtItensPedido(viIdxItePed).CODFILIALRETIRA          := vc_ItensPedido.CODFILIALRETIRA;    -- HIS.05093.2017                                      
          vtItensPedido(viIdxItePed).BONIFIC                  := vc_ItensPedido.BONIFIC;            -- MED-2521
          vtItensPedido(viIdxItePed).VLDESCICMISENCAO         := vc_ItensPedido.VLDESCICMISENCAO;   -- DDMEDICA-3065
          vtItensPedido(viIdxItePed).VLDESCSUFRAMA            := vc_ItensPedido.VLDESCSUFRAMA;      -- DDMEDICA-7584
          vtItensPedido(viIdxItePed).VLDESCPISSUFRAMA         := vc_ItensPedido.VLDESCPISSUFRAMA;   -- DDMEDICA-7584
          vtItensPedido(viIdxItePed).VLDESCREDUCAOPIS         := vc_ItensPedido.VLDESCREDUCAOPIS;   -- DDMEDICA-7584
          vtItensPedido(viIdxItePed).VLDESCREDUCAOCOFINS      := vc_ItensPedido.VLDESCREDUCAOCOFINS;-- DDMEDICA-7584
          vtItensPedido(viIdxItePed).BCSTRETANTERIOR          := vc_ItensPedido.BCSTRETANTERIOR;          -- DDMEDICA-7697
          vtItensPedido(viIdxItePed).VLICMSSUBSTITUTOANTERIOR := vc_ItensPedido.VLICMSSUBSTITUTOANTERIOR; -- DDMEDICA-7697
          vtItensPedido(viIdxItePed).VLICMSSTRETANTERIOR      := vc_ItensPedido.VLICMSSTRETANTERIOR;      -- DDMEDICA-7697
          vtItensPedido(viIdxItePed).STCLIENTEGNRE            := vc_ItensPedido.STCLIENTEGNRE;            -- DDMEDICA-7697
          vtItensPedido(viIdxItePed).VLDESCCMVPROMOCAOMED     := vc_ItensPedido.VLDESCCMVPROMOCAOMED;     -- DDMEDICA-7697
          vtItensPedido(viIdxItePed).CODICMTAB                := vc_ItensPedido.CODICMTAB;																						  
        END IF;  
         
      END LOOP; -- Fim Cursor de Itens do Pedido
  
      --------------------------------------------
      -- Processamento do Array de Itens do Pedido
      --------------------------------------------
      IF (vtItensPedido.COUNT > 0) THEN
        FOR viIdxItePed IN vtItensPedido.FIRST..vtItensPedido.LAST LOOP
        
          -- Pegar Registro do Array
          vrItensPedido := vtItensPedido(viIdxItePed); 
          
          -- DDMEDICA-7584 - Somatório dos valores unitários dos benefícios fiscais
          vnVlSomaDescUnitBenefFiscais := F_GET_SOMADESCUNITBENEFFISCAIS(NVL(vrItensPedido.VLDESCICMISENCAO,0),
                                                                         NVL(vrItensPedido.VLDESCSUFRAMA,0),
                                                                         NVL(vrItensPedido.VLDESCPISSUFRAMA,0),
                                                                         NVL(vrItensPedido.VLDESCREDUCAOPIS,0),
                                                                         NVL(vrItensPedido.VLDESCREDUCAOCOFINS,0));
          
                         
          -- Obtem os valores originais antes de somar o ST (após análise observou-se que arredondar o valor líquido no início garante maior acerto no ST)
          -- OBSERVAÇÃO: Passou a ser tirado o ST do FUNCEP - PCPEDI.VLFECP - HIS.04200.2017
          -- DDMEDICA-7584 - Usado o somatório dos valores unitários dos benefícios fiscais ao invés de somente a Desoneração de ICMS
          -- DDMEDICA-7697 - Usado o ST Recolhido Anteriormente
          vnPrecoLiqOriginal     := ROUND(( vrItensPedido.PVENDA    
                                          - NVL(vrItensPedido.ST, 0) 
                                          - NVL(vrItensPedido.VLICMSSTRETANTERIOR, 0) 
                                          - NVL(vrItensPedido.VLIPI, 0) 
                                          - NVL(vrItensPedido.VLREPASSE, 0) 
                                          - NVL(vrItensPedido.VLFECP,0) 
                                          + NVL(vnVlSomaDescUnitBenefFiscais,0) )
                                          , vrParametros.vnNumCasasDecVenda);
          vnPrecoTabOriginal     := ROUND(( vrItensPedido.PTABELA  
                                          - NVL(vrItensPedido.ST, 0) 
                                          - NVL(vrItensPedido.VLICMSSTRETANTERIOR, 0) 
                                          - NVL(vrItensPedido.VLIPI, 0) 
                                          - NVL(vrItensPedido.VLREPASSE, 0) 
                                          - NVL(vrItensPedido.VLFECP,0) 
                                          + NVL(vnVlSomaDescUnitBenefFiscais,0) )
                                          , vrParametros.vnNumCasasDecVenda);
          vnPrecoBaseRcaOriginal := ROUND(( vrItensPedido.PBASERCA 
                                          - NVL(vrItensPedido.ST, 0) 
                                          - NVL(vrItensPedido.VLICMSSTRETANTERIOR, 0) 
                                          - NVL(vrItensPedido.VLIPI, 0) 
                                          - NVL(vrItensPedido.VLREPASSE, 0) 
                                          - NVL(vrItensPedido.VLFECP,0) 
                                          + NVL(vnVlSomaDescUnitBenefFiscais,0) )
                                          , vrParametros.vnNumCasasDecVenda);
          
          -- Pega Preço de Fábrica armazenado no Item do Pedido
          vnPOriginal            := NVL(vrItensPedido.PORIGINAL,0);
                  
          -- Obtém valores do FUNCEP do Item do Pedido - HIS.04200.2017
          vrDadosFuncep.nVLBASEFCPICMS      := vrItensPedido.VLBASEFCPICMS;
          vrDadosFuncep.nVLBASEFCPST        := vrItensPedido.VLBASEFCPST;
          vrDadosFuncep.nVLBCFCPSTRET       := vrItensPedido.VLBCFCPSTRET;
          vrDadosFuncep.nPERFCPSTRET        := vrItensPedido.PERFCPSTRET;
          vrDadosFuncep.nVLFCPSTRET         := vrItensPedido.VLFCPSTRET;
          vrDadosFuncep.nPERFCPSN           := vrItensPedido.PERFCPSN;
          vrDadosFuncep.nVLFECP             := vrItensPedido.VLFECP;
          vrDadosFuncep.nVLACRESCIMOFUNCEP  := vrItensPedido.VLACRESCIMOFUNCEP;
          vrDadosFuncep.nPERACRESCIMOFUNCEP := vrItensPedido.PERACRESCIMOFUNCEP;
          vrDadosFuncep.nALIQICMSFECP       := vrItensPedido.ALIQICMSFECP;
          vrDadosFuncep.nVLCREDFCPICMSSN    := vrItensPedido.VLCREDFCPICMSSN;
          vrDadosFuncep.nCODCONFIGFUNCEPMED := vrItensPedido.CODCONFIGFUNCEPMED;

          -- Obtém os Valores do ST Antecipado do Item do Pedido - DDMEDICA-7697
          vrDadosStAntecip.nBCSTRETANTERIOR          := vrItensPedido.BCSTRETANTERIOR;
          vrDadosStAntecip.nVLICMSSUBSTITUTOANTERIOR := vrItensPedido.VLICMSSUBSTITUTOANTERIOR;
          vrDadosStAntecip.nVLICMSSTRETANTERIOR      := vrItensPedido.VLICMSSTRETANTERIOR;
          
          -- Obtém o Valor do ST CLIENTE GNRE - DDMEDICA-7697
          vnStClienteGnre                            := vrItensPedido.STCLIENTEGNRE;




          -------------------------------------------------------------------------------------------
          -------------------------------------------------------------------------------------------
          -------------------------------------------------------------------------------------------
          -- INICIO: Doação da Licitação - 6803.037246.2017 --
          ----------------------------------------------------
          ----------------------------------------------------
          ----------------------------------------------------
          IF (NVL(vc_CabecalhoPedido.CODEDITAL,0) > 0) AND
             (vrItensPedido.TIPOCONVERSAOPEDLICIT = 4) THEN
             
            -- Inicializa
            vrDadosDoacao := vrLimpaDadosDoacao;
            
            -- Como pode ocorrer desdobramento da PCPEDI, é necessário buscar informações por Produto
            SELECT COUNT(*)
                 , MIN(NUMSEQ)
                 , MAX(PCPEDI.QTPEDLICIT) -- A Quantidade Vendida do Empenho pode vir repetida se lote desdobrado
                 , SUM(QT)  
              INTO vrDadosDoacao.vnQtdeLotes
                 , vrDadosDoacao.vnPrimeiroNumSeqProduto
                 , vrDadosDoacao.edtQtdeVendida_EMPENHO
                 , vrDadosDoacao.vnQtdeTotalProduto
              FROM PCPEDI
             WHERE (NUMPED                    = vc_CabecalhoPedido.NUMPED)
               AND (CODPROD                   = vrItensPedido.CODPROD)
               AND (CODEDITAL                 = NVL(vrItensPedido.CODEDITAL,0))
               AND (NVL(LOTECONTRATO,'0')     = NVL(vrItensPedido.LOTECONTRATO,'0'))
               AND (NVL(NUMSEQITEMCONTRATO,0) = NVL(vrItensPedido.NUMSEQITEMCONTRATO,0));
               
            -- SE ACHOU O PRODUTO
            IF (vrDadosDoacao.vnQtdeLotes > 0) THEN
               
              -- SE FOR A PRIMEIRA OCORRÊNCIA DO PRODUTO
              IF (vtItensPedido(viIdxItePed).NUMSEQ = vrDadosDoacao.vnPrimeiroNumSeqProduto) THEN
                 
                -- Pega informações da Conversão gravadas no Item do Pedido
                vrDadosDoacao.vAPLICFATCONVPEDIDOVENDA := NVL(pi_vAplicFatConvPedidoVenda,' '); 
                vrDadosDoacao.edtFATORCONVERSAO        := NVL(vrItensPedido.FATORCONVERSAOPEDLICIT,0);
                -- Pega Preço de Tabela Original
                vrDadosDoacao.dPrecoTabela             := NVL(vnPrecoTabOriginal,0);
                   
                ----------------------------------------------------------------
                -- IMPORTANTE: ESTA REGRA EXISTE NA 2316, MANTER SINCRONIZADO --
                ----------------------------------------------------------------
                   
                --// Realiza a Conversão - Unidade do Edital para Embalagem
                --// Como Padrão neste processo é Multiplicação, como era antes, caso não tenha o parâmetro preenchido
                vrDadosDoacao.vdQtdeFinalOriginal := 0;
                if      (vrDadosDoacao.vAPLICFATCONVPEDIDOVENDA = 'M') and
                        (vrDadosDoacao.edtFATORCONVERSAO <> 0)  then
                  vrDadosDoacao.vdQtdeFinalOriginal := (vrDadosDoacao.edtQtdeVendida_EMPENHO * vrDadosDoacao.edtFATORCONVERSAO);
                elsif   (vrDadosDoacao.vAPLICFATCONVPEDIDOVENDA = 'D') and
                        (vrDadosDoacao.edtFATORCONVERSAO <> 0)   then
                  vrDadosDoacao.vdQtdeFinalOriginal := (vrDadosDoacao.edtQtdeVendida_EMPENHO / vrDadosDoacao.edtFATORCONVERSAO);
                elsif   (vrDadosDoacao.vAPLICFATCONVPEDIDOVENDA = 'N') then
                  vrDadosDoacao.vdQtdeFinalOriginal  := vrDadosDoacao.edtQtdeVendida_EMPENHO;
                else
                  vrDadosDoacao.vdQtdeFinalOriginal  := vrDadosDoacao.edtQtdeVendida_EMPENHO;                        
                end if;
                  
                --// HIS.00420.2017 - Regra somente para a opção 4,
                --//                  antes do CEIL truncar em 6 casas para ignorar os dízimos
                SELECT TRUNC(vrDadosDoacao.vdQtdeFinalOriginal,6) INTO vrDadosDoacao.vdQtdeFinalOriginal FROM DUAL;
                 
                -- Esta operação não será feita porque já tenho a quantidade final gravada no Item do Pedido (PCPEDI.QT),
                -- então não preciso calcular a quantidade final pelo arredondamento (porque teria que fazer também a regra dos múltiplos)
                --SELECT CEIL(vrDadosDoacao.vdQtdeFinalOriginal) INTO vrDadosDoacao.vdQtdeFinal FROM DUAL;
                vrDadosDoacao.vdQtdeFinal := NVL(vrDadosDoacao.vnQtdeTotalProduto,0); 
      
                -- Na 2316 os arredondamentos determinam o valor da quantidade final, 
                -- aqui já temos o limite da quantidade final que é a quantidade da PCPEDI, então ela determinará a diferença,
                -- não é necessário fazer os cálculos de arredondamento e multiplos pra chegar na quantidade final
                --// Quantidade enviada a mais - Por Diferença de Conversão de Embalagem
                --//edtQtdeDif.Value := (vdQtdeFinal - vdQtdeFinalOriginal);
                vrDadosDoacao.vdQtdeDif := NVL(vrDadosDoacao.vnQtdeTotalProduto,0) - NVL(vrDadosDoacao.vdQtdeFinalOriginal,0);
                IF (NVL(vrDadosDoacao.vdQtdeDif,0) < 0) THEN
                  vrDadosDoacao.vdQtdeDif := 0; -->> Dependendo de Corte Logístico pode tirar a doação
                END IF;
                 
                -- SE AINDA TEM QTDE DOAÇÃO
                IF (NVL(vrDadosDoacao.vdQtdeDif,0) > 0) THEN
                  --// Valor do Desconto Total -> Será usado no Retorno da Função
                  vrDadosDoacao.edtValorDesc := (vrDadosDoacao.vdQtdeDif * vrDadosDoacao.dPrecoTabela);
                  --// Valor do Desconto Unitário -> Campo somente Informativo
                  if (vrDadosDoacao.vdQtdeFinal <> 0) then
                    vrDadosDoacao.edtValorUnitDesc := (vrDadosDoacao.edtValorDesc / vrDadosDoacao.vdQtdeFinal);
                  else
                    vrDadosDoacao.edtValorUnitDesc := 0; 
                  end if;
                -- SE NÃO TEM MAIS QTDE DOAÇÃO
                ELSE
                  vrDadosDoacao.edtValorUnitDesc := 0; 
                END IF;                        
                
                -- Atualiza valores originais
                vnPrecoLiqOriginal     := ROUND((NVL(vrDadosDoacao.dPrecoTabela,0) - NVL(vrDadosDoacao.edtValorUnitDesc,0)),vrParametros.vnNumCasasDecVenda);
                vnPrecoBaseRcaOriginal := ROUND((NVL(vrDadosDoacao.dPrecoTabela,0) - NVL(vrDadosDoacao.edtValorUnitDesc,0)),vrParametros.vnNumCasasDecVenda);
                      
                -- A Qtde. Doação ficará concentrada no primeiro item
                vrItensPedido.QTDEDOACAOPEDLICIT := vrDadosDoacao.vdQtdeDif;   
                            
              -- A PARTIR DA SEGUNDA OCORRÊNCIA DO PRODUTO, PEGA PREÇOS DA PRIMEIRA OCORRÊNCIA (DESDOBRAMENTO DE LOTE)
              ELSE
             
                -- Pega os Preços já ajustados no primeiro Item do Produto
                SELECT ROUND((PCPEDI.PVENDA   - NVL(PCPEDI.ST, 0) - NVL(PCPEDI.VLIPI, 0) - NVL(PCPEDI.VLREPASSE, 0)),vrParametros.vnNumCasasDecVenda)
                     , ROUND((PCPEDI.PTABELA  - NVL(PCPEDI.ST, 0) - NVL(PCPEDI.VLIPI, 0) - NVL(PCPEDI.VLREPASSE, 0)),vrParametros.vnNumCasasDecVenda)
                     , ROUND((PCPEDI.PBASERCA - NVL(PCPEDI.ST, 0) - NVL(PCPEDI.VLIPI, 0) - NVL(PCPEDI.VLREPASSE, 0)),vrParametros.vnNumCasasDecVenda)
                  INTO vnPrecoLiqOriginal
                     , vnPrecoTabOriginal
                     , vnPrecoBaseRcaOriginal
                  FROM PCPEDI
                 WHERE (NUMPED  = vc_CabecalhoPedido.NUMPED)
                   AND (CODPROD = vrItensPedido.CODPROD)
                   AND (NUMSEQ  = vrDadosDoacao.vnPrimeiroNumSeqProduto);
                
                -- A Qtde. Doação ficará concentrada no primeiro item, não terá a partir do segundo item
                vrItensPedido.QTDEDOACAOPEDLICIT := 0;   
              
              END IF; -- FIM CONDIÇÃO PRIMEIRA OU DEMAIS OCORRÊNCIAS DO PRODUTO  
              
            END IF; -- FIM CONDIÇÃO SE ACHOU O PRODUTO
                          
          END IF; -- Fim Condição: Doação da Licitação                  
          ----------------------------------------------------
          ----------------------------------------------------
          ----------------------------------------------------
          --   FIM: Doação da Licitação - 6803.037246.2017  --
          -------------------------------------------------------------------------------------------
          -------------------------------------------------------------------------------------------
          -------------------------------------------------------------------------------------------
  
          
  
          -- Obtém Preço Fábrica
          P_OBTEM_PMC_PRODUTO(vc_CabecalhoPedido.CODFILIAL,
                              vrItensPedido.CODPROD,
                              vc_CabecalhoPedido.ESTENT,
                              vnNumRegiao, -- HIS.05093.2017 - Região do Pedido ou do Cliente
                              vnAuxPrecoMaxConsum, -->> Substitui o Preço Máximo Consumidor
                              vnAuxPrecoFabrica,   -->> Substitui o Preço Fábrica
                              vvMsgPmcUf,
                              vc_CabecalhoPedido.CODCLI); -- DDVENDAS-35830
          
         /********************************************************************************
          SE CHAMADO PARA RECALCULAR O PREÇO DE TABELA PELO PREÇO FÁBRICA - HIS.00558.2016
          ********************************************************************************/
          IF (NVL(pi_vTipoChamada,' ') = 'P') THEN
                 
            -- Se tem Preço Fábrica
            IF (NVL(vnAuxPrecoFabrica,0) > 0) THEN
              -- Substitui o PTABELA e PORIGINAL
              vnPrecoTabOriginal := vnAuxPrecoFabrica;
              vnPOriginal        := vnAuxPrecoFabrica;
            END IF;                                               
            
         /********************************************************************************
          SE CHAMADO PARA RECALCULAR O PREÇO DE TABELA PELO PREÇO VENDA - HIS.05093.2017
          MIN   TABELA   VENDA          TABELA   VENDA
          4     8        6       --->>> 6        6
          ********************************************************************************/
          ELSIF (NVL(pi_vTipoChamada,' ') = 'V') THEN
  
            -- Iguala o Preço de Tabela ao Preço de Venda (Ignora a parte que foi Desconto Comercial Negociado, essa tem que sair como desconto na nota)
            IF (NVL(vrItensPedido.VLDESCNEG,0) > 0)       AND
               (NVL(vrItensPedido.TIPODESCNEG,'N') = 'C') THEN
              vnPrecoTabOriginal := (vnPrecoLiqOriginal + NVL(vrItensPedido.VLDESCNEG,0));
            ELSE
              vnPrecoTabOriginal := vnPrecoLiqOriginal;
          END IF;        
  
          END IF; -- Fim Condição: pi_vTipoChamada      
  
          -- Dados Tributação
          BEGIN
            SELECT PCTRIBUT.PERDESCCUSTO
                 , PCTRIBUT.CODICMTAB
                 , PCTRIBUT.CODICMTABPF
                 , PCTRIBUT.PERDESCREPASSE
                 , PCTRIBUT.ALIQICMSFECP        -- HIS.04200.2017               
				 , NVL(PCTRIBUT.UTILIZAICMTABFLEX, 'N') UTILIZAICMTABFLEX																   
              INTO vrDadosTributacao.vnPerDescCusto
                 , vrDadosTributacao.vnCodicmtab
                 , vrDadosTributacao.vnCodicmtabpf          
                 , vrDadosTributacao.vnPerDescRepasse
                 , vrDadosTributacao.vnAliqIcmsFecp        -- HIS.04200.2017               
				 , vrDadosTributacao.vsUtilizaICMTABFlex  													   
              FROM PCTRIBUT
             WHERE (PCTRIBUT.CODST = vrItensPedido.CODST);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vrDadosTributacao.vnPerDescCusto        := 0;
              vrDadosTributacao.vnCodicmtab           := 0;
              vrDadosTributacao.vnCodicmtabpf         := 0;
              vrDadosTributacao.vnPerDescRepasse      := 0;
              vrDadosTributacao.vnAliqIcmsFecp        := 0;   -- HIS.04200.2017               
			  vrDadosTributacao.vsUtilizaICMTABFlex   := 'N';  																
          END;           
          
          IF (vrDadosTributacao.vnCodicmtabpf IS NULL) THEN
            vrDadosTributacao.vbCodicmtabpf_enulo := TRUE;
          ELSE
            vrDadosTributacao.vbCodicmtabpf_enulo := FALSE;
          END IF;
          
          ---------------------
          -- Cálculo do Repasse
          ---------------------
  
          -- Inicializa Valores
          vnVlRepasse := 0;
          vnVlOutros  := 0;
    
          if vc_CabecalhoPedido.CONDVENDA IN (1,5) then
          
            if vrItensPedido.TIPOMERC in ('M','MA','L') and vrDadosCliente.vvRepasse = 'S' then
            
              -- Refaz Preço Original (PRECO FÁBRICA)
              --IF (NVL(vrItensPedido.TIPOMERC,' ') IN ('M','MA','L')) THEN -- Se Medicamento
              --  IF (NVL(vrDadosRegiao.vvRegiaoZfm,'N') = 'S') THEN
              --    vnPOriginal := vrItensPedido.CUSTOREPZFM;
              --  ELSE
              --    vnPOriginal := vrItensPedido.CUSTOREP;
              --  END IF;
              --ELSE
              --  vnPOriginal := vnPrecoTabOriginal;
              --END IF;
              IF (NVL(vnAuxPrecoFabrica,0) > 0) THEN
                vnPOriginal := vnAuxPrecoFabrica; -- Retornado por PRC_MED_OBTEM_PMC_PRODUTO()
              END IF;
                                               
              -- Tipo de Aplicação do Repasse = Acréscimo sobre Preço Fábrica 
              if (nvl(vrParametrosFilial.vvTipoAplicRepasseFilial,'AB') = 'AB') then
                 vnVlRepasse := NVL(vnPOriginal,0) * (NVL(vrDadosTributacao.vnPerDescRepasse,0)/100);
                 vnVlOutros  := NVL(vnVlRepasse,0);
              -- Tipo de Aplicação do Repasse = Acréscimo sobre Preço Liquido
              elsif (nvl(vrParametrosFilial.vvTipoAplicRepasseFilial,'AB') = 'AL') then
                 vnVlRepasse := NVL(vnPrecoLiqOriginal,0) * (NVL(vrDadosTributacao.vnPerDescRepasse,0)/100);
                 vnVlOutros  := NVL(vnVlRepasse,0);
              end if;
                    
              ---------------------------------------------------------------      
              -- Somará ao PTabela e PVenda o VLREPASSE no UPDATE MAIS ABAIXO
              ---------------------------------------------------------------      
                      
            end if;
          end if;
          
          ----------------
          -- Cálculo do ST
          ----------------
          
          -- Observação do ST
          vvObservacaoStFonte  := NULL;
          
          -- ST - DDMEDICA-7697
          vnStClienteGnreFonte := 0;
          vnBaseicst           := 0;
          vnSt                 := 0;          
          
          --DDMEDICA-3065--Pode ter repasse e st--IF (NVL(vnVlRepasse,0) = 0) THEN                                 
          -- Chama Procedure para Calcular ST Fonte
          -- 4.0 - HIS.04200.2017
          -- DDMEDICA-7697 - Cálculo com o ST Recolhido Anteriormente
          P_OBTEM_STFONTE_42(vc_CabecalhoPedido.CODFILIAL,
                             vrItensPedido.CODPROD,
                             vc_CabecalhoPedido.CODCLI,
                             vc_CabecalhoPedido.NUMREGIAO,
                             vc_CabecalhoPedido.CONDVENDA,
                             100, -- pi_nPercVenda
                             vrItensPedido.CODST,
                             vnPrecoLiqOriginal,
                             vrItensPedido.VLIPI,
                             vrItensPedido.PRECOMAXCONSUM,
                             NULL, -- pi_nValorUltEnt
                             NULL, -- pi_nCustoNfSemSt
                             vnPrecoTabOriginal,
                             'N',  -- pi_vSomenteIVATribut
                             'S',  -- pi_vPesquisarCustos
                             NVL(vrItensPedido.BONIFIC,'N'),  -- MED-2521
                             0,    -- Sem Despesas acessórias
                             vnBaseicst,             -->> RETORNA A BASE DO ST
                             vnSt,                   -->> RETORNA O VALOR DO ST
                             vvMsgRetObterStFonte,   -->> Retorna a Mensagem de Erro
                             vvRegimeEspIsenStFonte, -->> RETORNA SE REGIME ESPECIAL ISENÇÃO ST FONTE
                             vnAliqIcms1,            -->> RETORNA ALIQ ICMS 1
                             vnAliqIcms2,            -->> RETORNA ALIQ ICMS 2
                             vnIva,                  -->> RETORNA IVA
                             vnPercBaseRedStFonte,   -->> RETORNA PERC. REDUÇÃO  
                             pi_vTipoChamada,  
                             vrItensPedido.QT,
                             pi_nNumPed,
                             vc_CabecalhoPedido.CODFILIALNF,
                             vnPautaFonte,         -- HIS.01838.2017
                             vvObservacaoStFonte,  -- HIS.01838.2017
                             vvIndEscalaRelevante, -- HIS.03371.2017
                             vvCnpjFabricante,     -- HIS.03371.2017
                             vvFabricante,         -- HIS.03371.2017
                             vrDadosFuncep.nVLBASEFCPICMS,      -- HIS.04200.2017
                             vrDadosFuncep.nVLBASEFCPST,        -- HIS.04200.2017
                             vrDadosFuncep.nVLBCFCPSTRET,       -- HIS.04200.2017
                             vrDadosFuncep.nPERFCPSTRET,        -- HIS.04200.2017
                             vrDadosFuncep.nVLFCPSTRET,         -- HIS.04200.2017
                             vrDadosFuncep.nPERFCPSN,           -- HIS.04200.2017
                             vrDadosFuncep.nVLFECP,             -- HIS.04200.2017
                             vrDadosFuncep.nVLACRESCIMOFUNCEP,  -- HIS.04200.2017
                             vrDadosFuncep.nPERACRESCIMOFUNCEP, -- HIS.04200.2017
                             vrDadosFuncep.nALIQICMSFECP,       -- HIS.04200.2017
                             vrDadosFuncep.nVLCREDFCPICMSSN,    -- HIS.04200.2017                                   
                             vrDadosFuncep.nCODCONFIGFUNCEPMED,
                             'F', -- pi_vOrdemCalculo
                             'N', -- pi_vMemoriaCalculo
                             0,   -- pi_nValorNotaFiscal
                             vc_CabecalhoPedido.TRIBUTPEDIDOAVARIAPERDA,
                             vrDadosStAntecip.nBCSTRETANTERIOR,          -- DDMEDICA-7697
                             vrDadosStAntecip.nVLICMSSUBSTITUTOANTERIOR, -- DDMEDICA-7697
                             vrDadosStAntecip.nVLICMSSTRETANTERIOR,      -- DDMEDICA-7697
                             vnStClienteGnreFonte,                       -- DDMEDICA-7697
                             vnPmPfMedicamento,                          -- DDMEDICA-7697
                             vvClienteFonteSt,                           -- DDMEDICA-7697
                             vvEstEnt                                    -- DDVENDAS-33718
                             );
                                      
          IF (vvMsgRetObterStFonte IS NOT NULL) THEN
            -- Se ocorreram erros ao Obter ST Fonte
            RAISE e_CalcularStFonte;
          END IF;            
          
          -- DDMEDICA-7697 - ST FONTE GNRE
          IF (vvClienteFonteSt = 'S') THEN
            vnStClienteGnre := vnStClienteGnreFonte;
          END IF;
          
          -- Dados PCEST
          IF (NVL(vrParametrosFilial.vvOrigemCustoFilialRetira,'X') = 'V') THEN
            BEGIN  
              SELECT PCEST.CUSTOFIN,
                     PCEST.CUSTOREAL
                INTO vrDadosEstoque.vnCustoFin
                   , vrDadosEstoque.vnCustoReal
                FROM PCEST
               WHERE (PCEST.CODPROD   = vrItensPedido.CODPROD)
                 AND (PCEST.CODFILIAL = vc_CabecalhoPedido.CODFILIAL);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                vrDadosEstoque.vnCustoFin  := 0;
                vrDadosEstoque.vnCustoReal := 0;
            END;
          ELSE
            BEGIN  
              SELECT PCEST.CUSTOFIN,
                     PCEST.CUSTOREAL
                INTO vrDadosEstoque.vnCustoFin
                   , vrDadosEstoque.vnCustoReal
                FROM PCEST
               WHERE (PCEST.CODPROD   = vrItensPedido.CODPROD)
                 AND (PCEST.CODFILIAL = NVL(vrItensPedido.CODFILIALRETIRA,vc_CabecalhoPedido.CODFILIAL));
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                vrDadosEstoque.vnCustoFin  := 0;
                vrDadosEstoque.vnCustoReal := 0;
            END;
          END IF;
          
          -- MED-1096 - Custo do Cross Docking
          IF (NVL(vc_CabecalhoPedido.NUMTRANSENTCROSSDOCK,0) > 0) THEN
            BEGIN
              SELECT PCMOVCOMPLE.CUSTOULTENTCONT
                INTO vrDadosEstoque.vnCustoFin
                FROM PCMOV
                   , PCMOVCOMPLE
               WHERE (PCMOV.NUMTRANSENT  = vc_CabecalhoPedido.NUMTRANSENTCROSSDOCK)
                 AND (PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM)
                 AND (PCMOV.CODPROD      = vrItensPedido.CODPROD)
                 AND (ROWNUM      = 1);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                NULL;
            END;
          END IF;      
          
          vnPerComCmv := NVL(vrItensPedido.PERCOM,0);
          IF (NVL(vrParametros.vvincluircomissaocmvvenda,'S') = 'N') THEN
            vnPerComCmv := 0;
          END IF;
                  
          -- Recalcular CMV
          P_CALCULARCMV_MED(vrParametros.vsAbaterImpostosComissaoRca,
                            vrParametros.vsAplicarIndiceCmv,
                            vrParametros.vsIncluirComissaoSugPvendaCmv,
                            vrParametros.vnTxVenda,
                            vc_CabecalhoPedido.TIPOFJ,
                            vc_CabecalhoPedido.UTILIZAIESIMPLIFICADA,
                            vc_CabecalhoPedido.IEENT,
                            vrItensPedido.FRETEESPECIAL,
                            vrDadosRegiao.vnPerFreteTerceiros,
                            vrDadosRegiao.vnPerFreteEspecial,
                            vrDadosEstoque.vnCustoFin,
                            vrDadosEstoque.vnCustoReal,
                            vrDadosTributacao.vnPerDescCusto,
                            case when (vrDadosTributacao.vsUtilizaICMTABFlex = 'S') then
                                vrItensPedido.CODICMTAB
                              else
                                vrDadosTributacao.vnCodicmtab
                            end,
                            vrDadosTributacao.vbCodicmtabpf_enulo,
                            case when (vrDadosTributacao.vsUtilizaICMTABFlex = 'S') then
                                vrItensPedido.CODICMTAB
                              else
                                vrDadosTributacao.vnCodicmtabpf
                            end,	
                            ROUND((NVL(vnPrecoLiqOriginal,0) + 
                                    NVL(vnst,0) + 
                                     NVL(vrDadosStAntecip.nVLICMSSTRETANTERIOR,0) + -- DDMEDICA-7697 - ST Antecip
                                      NVL(vrDadosFuncep.nVLFECP,0)),vrParametros.vnNumCasasDecVenda), -- Novo PVENDA // HIS.04200.2017 - Acrescido o ST FCP 
                            vnPerComCmv, -->> Percom CMV
                            (NVL(vnSt,0) +
                               NVL(vrDadosFuncep.nVLFECP,0)), -- HIS.04200.2017 - ST FCP                            
                            vrItensPedido.VLIPI,
                            0,
                            vc_CabecalhoPedido.CONTRIBUINTE,
                            NVL(vrItensPedido.VLDESCCMVPROMOCAOMED,0),    -- DDMEDICA-7697
                            NVL(vrDadosStAntecip.nVLICMSSTRETANTERIOR,0), -- DDMEDICA-7697
                            vrValoresCusto.vnPerfretecmv,
                            vrValoresCusto.vnCustofinest,
                            vrValoresCusto.vnTxvenda,
                            vrValoresCusto.vnPerdesccusto,
                            vrValoresCusto.vnCodicmtab,
                            vrValoresCusto.vnVlcustoreal,
                            vrValoresCusto.vnVlcustofin,
                            vrValoresCusto.vnVldesccustocmv);
                   
          -- 5666.044130.2018 - Rebaixa de CMV
          IF (NVL(vtItensPedido(viIdxItePed).VLVERBACMV,0) > 0)
             and (NVL(vrItensPedido.VLDESCCMVPROMOCAOMED,0) = 0) THEN
               vrValoresCusto.vnVlcustofin := NVL(vrValoresCusto.vnVlcustofin,0) - NVL(vtItensPedido(viIdxItePed).VLVERBACMV,0); -- 5666.044130.2018
          END IF;
          
          -- Verificando se existe registro de PEPS
          vnqtregistropepstemp := 0;
          IF (pi_vTipoChamada = 'F') AND
             (vvmedcalcularstpelopeps = 'S') THEN
             SELECT COUNT(*)
               INTO vnqtregistropepstemp
               FROM PCPEPSSALDOTEMP;
          END IF;
          
          -- Se Desoneração da Licitação não calcula PEPS - 6803.037246.2017
          IF (NVL(pi_vCalculaDesoneracaoLicit,'N') = 'S') AND
             (NVL(vc_CabecalhoPedido.CODEDITAL,0) > 0)    THEN
            vnqtregistropepstemp := 0;
          END IF;
  
          -- Se tem Registro de PEPS para o Item do Pedido
          IF (NVL(vnqtregistropepstemp,0) > 0) THEN
          
            -- Insere Item pelo PEPS
            INSERT INTO PCPEDI(
                     NUMPED,
                     DATA,
                     CODCLI,
                     CODPROD,
                     CODUSUR,
                     QT,
                     PVENDA,
                     PTABELA,
                     NUMCAR,
                     POSICAO,
                     ST,
                     VLCUSTOFIN,
                     VLCUSTOREAL,
                     PERCOM,
                     PERDESC,
                     QTFALTA,
                     NUMSEQ,
                     TIPOPESO,
                     PERCOMTAB,
                     PERDESCTAB,
                     CODMOTNAOCOMPRA,
                     VLDESCCUSTOCMV,
                     QTSEPARADA,
                     QTVENDAEMB,
                     PVENDAEMB,
                     VLOUTROS,
                     QTEMBALAGEM,
                     PVENDAEMBALAGEM,
                     CODAUXILIAR,
                     VLCUSTOREP,
                     VLCUSTOCONT,
                     CODCERTIFIC,
                     PVENDABASE,
                     NOMECONCORRENTE,
                     PRECO,
                     PRAZO,
                     QTNAOCOMPRA,
                     CODFILIALRETIRA,
                     NUMTIRA,
                     CODFUNCSEP,
                     VLDESCSUFRAMA,
                     NUMLOTE,
                     VLDESCREPASSE,
                     REFCOR,
                     CODFUNCCONF,
                     DATACONF,
                     VLDESCICMISENCAO,
                     QTORIGINAL,
                     VLDESCFORNEC,
                     VLFRETE,
                     VLIPI,
                     QTORIG,
                     QTSEPARARUN,
                     QTSEPARARCX,
                     CODST,
                     VLDESCFIN,
                     PERCIPI,
                     IVA,
                     ALIQICMS1,
                     ALIQICMS2,
                     PAUTA,
                     PERCBASERED,
                     VLDESCCOM,
                     PERDESCCOM,
                     PERDESCFIN,
                     VLBONIFIC,
                     PERBONIFIC,
                     PORIGINAL,
                     VLREBAIXACMV,
                     NUMAPLIC,
                     PERFRETECMV,
                     VLDESCRODAPE,
                     STCLIENTEGNRE,
                     IMPRIME,
                     COMPLEMENTO,
                     CUSTOFINEST,
                     PERCBASEREDSTFONTE,
                     PERCBASEREDST,
                     PERDESCCUSTO,
                     CODICMTAB,
                     TXVENDA,
                     PERCOM2,
                     PERCOM3,
                     PERCISS,
                     VLISS,
                     NUMTRANSWMS,
                     CODPROMOCAO,
                     PRAZOMEDIO,
                     LOCALIZACAO,
                     VLREPASSE,
                     PBONIFIC,
                     PERCVENDA,
                     VLDESCPISSUFRAMA,
                     CODDEGUSTACAO,
                     QTLOCALIZADA,
                     PERDESCFLEX,
                     VLDESCFLEX,
                     PERREDCOMISS,
                     VLREDCOMISS,
                     TIPODESCAPLICADO,
                     PBASERCA,
                     PESOBRUTO,
                     NUMVERBAREBCMV,
                     CONDVENDA,
                     CODPLPAG,
                     EANCODPROD,
                     BRINDE,
                     PERCOMSUP,
                     PERREDCOMISSSUP,
                     VLREDCOMISSSUP,
                     BASEICST,
                     NUMOP,
                     QTCX,
                     QTPECAS,
                     CODECF,
                     LETRACOMISS,
                     VLACRESCRODAPE,
                     NUMCONFERENCIA,
                     PERDESCISENTOICMS,
                     PERCOMPROF,
                     NUMCARAUX,
                     PVENDA1,
                     PERCAGREGADORST,
                     VLVERBACMVCLI,
                     VLOUTRASDESP,
                     EXPORTADOSERVINT,
                     DTEXPORTACAOSERVINT,
                     DTIMPORTACAOSERVPRINC,
                     IMPORTADOSERVPRINC,
                     CODVASILHAME,
                     QTAPANHA,
                     QTUNITCX,
                     TRUNCARITEM,
                     ABASTECIDO,
                     QTIMEDIATA,
                     CODFUNCLANC,
                     ROTINALANC,
                     DTLANC,
                     CODFUNCULTALTER,
                     ROTINAULTLALTER,
                     DTULTLALTER,
                     CODFUNCALTERACAOOS,
                     DTALTERACAOOS,
                     QTPENDOS,
                     VLDIFALIQUOTAS,
                     BASEDIFALIQUOTAS,
                     PERCDIFALIQUOTAS,
                     GERAGNRE_CNPJCLIENTE,
                     PRODDESCRICAOCONTRATO,
                     NUMOS,
                     DTINICIALSEP,
                     DTFINALSEP,
                     DATACONFFIM,
                     SITUACAOOS,
                     NUMVIASOS,
                     DTINICIALPEND,
                     DTFINALPEND,
                     CODFUNCPEND,
                     DTLIBOS,
                     CODFUNCLIBOS,
                     LOCALIZACAOOS,
                     NUMOSORIGEM,
                     PERDESCPOLITICA,
                     PVENDAANTERIOR,
                     TIPOENTREGA,
                     TVBONIF,
                     CODIGOBRINDE,
                     CODFUNCAJUSTEOS,
                     DTAJUSTEOS,
                     POLITICAPRIORITARIA,
                     TIPOCALCULOST,
                     QTUNITEMB,
                     VLFRETE_RATEIO,
                     VLOUTRAS_RATEIO,
                     BASEICST_ANT_RATEIO,
                     ST_ANT_RATEIO,
                     ST_DIF_RATEIO,
                     VLVERBACMV,
                     CODFUNCCONF2,
                     TIPOSEPARACAO,
                     NUMVOLUMESCONFERENCIA,
                     ROTINA,
                     PERCDESCPIS,
                     PERCDESCCOFINS,
                     VLDESCREDUCAOPIS,
                     VLDESCREDUCAOCOFINS,
                     PERCOM4,
                     NUMETIQUETA,
                     DTGERACAOOS,
                     CODFUNCALTLOTE,
                     PRECOFVBRUTO,
                     ALTERNATIVO,
                     SIGLAQUALIDADE,
                     VOLUMEDESEJADO,
                     CODBASE,
                     CODFORMULA,
                     USADEBCREDRCABRIND,
                     CODDESCONTO,
                     CODCOMBO,
                     DTENTREGA,
                     MOVIMENTACONTACORRENTERCA,
                     IDPATRIMONIO,
                     VLREDPVENDASIMPLESNA,
                     VLREDCMVSIMPLESNAC,
                     PERDESCFOB,
                     PRECOMAXCONSUM,
                     DESCPRECOFAB,
                     ROTINALANCULTALT,
                     NUMCAIXA,
                     PERCICM,
                     CODCONTRATO,
                     PRODDESCRICAODANFE,
                     IDVENDA,
                     PERCDESCINDUSTRIA,
                     PERDESCBOLETO,
                     CODLINHAPRAZO,
                     STPBASERCA,
                     STPTABELA,
                     QTLITRAGEM,
                     BONIFIC,
                     RP_IMEDIATA,
                     GRUPOFATURAMENTO,
                     PARTICIPAGIRO,
                     QTUN,
                     VLIPIOUTRAS,
                     PERCIPIOUTRAS,
                     VLDESCABATIMENTO,
                     PERCDESCABATIMENTO,
                     QTRESERVANT,
                     VLDESCBOLETO,
                     NUMSEQITEMCONTRATO,
                     NUMLISTA,
                     ROTINALANCBRINDE,
                     SUGESTAO,
                     CODEMITENTEITEMPEDIDO,
                     PERDESCINICOMISS,
                     PERDESCFIMCOMISS,
                     CONCEDERMAIORCOMISSREG,
                     VLSUBTOTITEM,
                     PERDESCNEGOCIADO,
                     FORMANEGOCIACAO,
                     PERDESCAVISTA,
                     NEGOCIACAOPOSTERIOR,
                     CODPRECOFIXO,
                     VLACRESFRETEKG,
                     STATUSSUCATA,
                     PTABELAAUTPECAS,
                     GRPREGRABRINDE,
                     NUMITEMPED,
                     VLITEMTRIBUTOS,
                     PERCTRIBUTOS,
                     TOTALIZADORALIQUOTA,
                     PERDESCPAUTA,
                     ORIGEMST,
                     VLDESCSOCIOTORCEDOR,
                     QTFALTADIGITACAO,
                     VLSALDORCA,
                     CODPROMOCAOMED,
                     INICIOINTERVALODESCQUANT,
                     ALTDESCPROMOCMED,
                     NUMRECOPI,
                     NUMERORECOPI,
                     UNIDADE,
                     AMBIENTE,
                     TAXACASOMOEDAREAL,
                     CODMOEDAESTRAGEIRA,
                     VLRMOEDAESTRAGEIRA,
                     QTDIASENTREGAITEM,
                     DTINICIOPROMOLOTE,
                     DTFIMPROMOLOTE,
                     PERCIPIECF,
                     VLIPIECF,
                     BASEIPIECF,
                     USAUNIDADEMASTER,
                     CLASSEVENDA,
                     QT_SEPARADAMANIF,
                     LOTECONTRATO,
                     PARTICIPACOMISSGARANTIDA,
                     CODCONTROLEVASILHAME,
                     CODVASILHAMEECF,
                     QTSAIDAVASILHAME,
                     QTVENDIDAVASILHAME,
                     VLACRESCVASILHAME,
                     PVENDAVASILHAME,
                     CODUSUR2,
                     CODUSUR3,
                     CODUSUR4,
                     REGIMEESPISENSTFONTE,
                     TRANSFERIURCALINHA,
                     NUMTRANSPEPS,
                     -- HIS.03371.2017
                     INDESCALARELEVANTE,
                     CNPJFABRICANTE,
                     FABRICANTE,
                     VLBASEFCPICMS,      -- HIS.04200.2017
                     VLBASEFCPST,        -- HIS.04200.2017
                     VLBCFCPSTRET,       -- HIS.04200.2017
                     PERFCPSTRET,        -- HIS.04200.2017
                     VLFCPSTRET,         -- HIS.04200.2017
                     PERFCPSN,           -- HIS.04200.2017
                     VLFECP,             -- HIS.04200.2017
                     VLACRESCIMOFUNCEP,  -- HIS.04200.2017
                     PERACRESCIMOFUNCEP, -- HIS.04200.2017
                     ALIQICMSFECP,       -- HIS.04200.2017
                     VLCREDFCPICMSSN,    -- HIS.04200.2017                                                              
                     CODCONFIGFUNCEPMED,
                     PMPFMEDICAMENTO
                     )
            SELECT   P.NUMPED,
                     P.DATA,
                     P.CODCLI,
                     P.CODPROD,
                     P.CODUSUR,
                     T.QTSALDO,
                     NVL(vnPrecoLiqOriginal,0)     + NVL(T.ST,0), -->> USAR O VALOR ST DO PEPS
                     NVL(vnPrecoTabOriginal,0)     + NVL(T.ST,0), -->> USAR O VALOR ST DO PEPS
                     P.NUMCAR,
                     P.POSICAO,
                     NVL(T.ST,0), -->> USAR O VALOR ST DO PEPS 
                     vrValoresCusto.vnvlcustofin,
                     vrValoresCusto.vnvlcustoreal,
                     P.PERCOM,
                     P.PERDESC,
                     P.QTFALTA,
                     NVL((SELECT MAX(NUMSEQ) FROM PCPEDI WHERE NUMPED = P.NUMPED),0) + ROWNUM,
                     P.TIPOPESO,
                     P.PERCOMTAB,
                     P.PERDESCTAB,
                     P.CODMOTNAOCOMPRA,
                     vrValoresCusto.vnvldesccustocmv,
                     P.QTSEPARADA,
                     P.QTVENDAEMB,
                     P.PVENDAEMB,
                     P.VLOUTROS,
                     P.QTEMBALAGEM,
                     P.PVENDAEMBALAGEM,
                     P.CODAUXILIAR,
                     P.VLCUSTOREP,
                     P.VLCUSTOCONT,
                     P.CODCERTIFIC,
                     P.PVENDABASE,
                     P.NOMECONCORRENTE,
                     P.PRECO,
                     P.PRAZO,
                     P.QTNAOCOMPRA,
                     P.CODFILIALRETIRA,
                     P.NUMTIRA,
                     P.CODFUNCSEP,
                     P.VLDESCSUFRAMA,
                     P.NUMLOTE,
                     P.VLDESCREPASSE,
                     P.REFCOR,
                     P.CODFUNCCONF,
                     P.DATACONF,
                     P.VLDESCICMISENCAO,
                     P.QTORIGINAL,
                     P.VLDESCFORNEC,
                     P.VLFRETE,
                     P.VLIPI,
                     P.QTORIG,
                     P.QTSEPARARUN,
                     P.QTSEPARARCX,
                     P.CODST,
                     P.VLDESCFIN,
                     P.PERCIPI,
                     vnIva,
                     vnAliqIcms1,
                     vnAliqIcms2,
                     P.PAUTA,
                     P.PERCBASERED,
                     P.VLDESCCOM,
                     P.PERDESCCOM,
                     P.PERDESCFIN,
                     P.VLBONIFIC,
                     P.PERBONIFIC,
                     P.PORIGINAL,
                     P.VLREBAIXACMV,
                     P.NUMAPLIC,
                     vrValoresCusto.vnperfretecmv,
                     P.VLDESCRODAPE,
                     P.STCLIENTEGNRE,
                     P.IMPRIME,
                     P.COMPLEMENTO,
                     vrValoresCusto.vncustofinest,
                     vnPercBaseRedStFonte,
                     P.PERCBASEREDST,
                     vrValoresCusto.vnperdesccusto,
                     vrValoresCusto.vncodicmtab,
                     vrValoresCusto.vntxvenda,
                     P.PERCOM2,
                     P.PERCOM3,
                     P.PERCISS,
                     P.VLISS,
                     P.NUMTRANSWMS,
                     P.CODPROMOCAO,
                     P.PRAZOMEDIO,
                     P.LOCALIZACAO,
                     P.VLREPASSE,
                     P.PBONIFIC,
                     P.PERCVENDA,
                     P.VLDESCPISSUFRAMA,
                     P.CODDEGUSTACAO,
                     P.QTLOCALIZADA,
                     P.PERDESCFLEX,
                     P.VLDESCFLEX,
                     P.PERREDCOMISS,
                     P.VLREDCOMISS,
                     P.TIPODESCAPLICADO,
                     NVL(vnPrecoBaseRcaOriginal,0) + NVL(T.ST,0), -->> USAR O VALOR ST DO PEPS
                     P.PESOBRUTO,
                     P.NUMVERBAREBCMV,
                     P.CONDVENDA,
                     P.CODPLPAG,
                     P.EANCODPROD,
                     P.BRINDE,
                     P.PERCOMSUP,
                     P.PERREDCOMISSSUP,
                     P.VLREDCOMISSSUP,
                     T.BASEICST, -->> USAR A BASE ST DO PEPS
                     P.NUMOP,
                     P.QTCX,
                     P.QTPECAS,
                     P.CODECF,
                     P.LETRACOMISS,
                     P.VLACRESCRODAPE,
                     P.NUMCONFERENCIA,
                     P.PERDESCISENTOICMS,
                     P.PERCOMPROF,
                     P.NUMCARAUX,
                     P.PVENDA1,
                     P.PERCAGREGADORST,
                     P.VLVERBACMVCLI,
                     P.VLOUTRASDESP,
                     P.EXPORTADOSERVINT,
                     P.DTEXPORTACAOSERVINT,
                     P.DTIMPORTACAOSERVPRINC,
                     P.IMPORTADOSERVPRINC,
                     P.CODVASILHAME,
                     P.QTAPANHA,
                     P.QTUNITCX,
                     P.TRUNCARITEM,
                     P.ABASTECIDO,
                     P.QTIMEDIATA,
                     P.CODFUNCLANC,
                     P.ROTINALANC,
                     P.DTLANC,
                     P.CODFUNCULTALTER,
                     P.ROTINAULTLALTER,
                     P.DTULTLALTER,
                     P.CODFUNCALTERACAOOS,
                     P.DTALTERACAOOS,
                     P.QTPENDOS,
                     P.VLDIFALIQUOTAS,
                     P.BASEDIFALIQUOTAS,
                     P.PERCDIFALIQUOTAS,
                     P.GERAGNRE_CNPJCLIENTE,
                     P.PRODDESCRICAOCONTRATO,
                     P.NUMOS,
                     P.DTINICIALSEP,
                     P.DTFINALSEP,
                     P.DATACONFFIM,
                     P.SITUACAOOS,
                     P.NUMVIASOS,
                     P.DTINICIALPEND,
                     P.DTFINALPEND,
                     P.CODFUNCPEND,
                     P.DTLIBOS,
                     P.CODFUNCLIBOS,
                     P.LOCALIZACAOOS,
                     P.NUMOSORIGEM,
                     P.PERDESCPOLITICA,
                     P.PVENDAANTERIOR,
                     P.TIPOENTREGA,
                     P.TVBONIF,
                     P.CODIGOBRINDE,
                     P.CODFUNCAJUSTEOS,
                     P.DTAJUSTEOS,
                     P.POLITICAPRIORITARIA,
                     P.TIPOCALCULOST,
                     P.QTUNITEMB,
                     P.VLFRETE_RATEIO,
                     P.VLOUTRAS_RATEIO,
                     P.BASEICST_ANT_RATEIO,
                     P.ST_ANT_RATEIO,
                     P.ST_DIF_RATEIO,
                     P.VLVERBACMV,
                     P.CODFUNCCONF2,
                     P.TIPOSEPARACAO,
                     P.NUMVOLUMESCONFERENCIA,
                     P.ROTINA,
                     P.PERCDESCPIS,
                     P.PERCDESCCOFINS,
                     P.VLDESCREDUCAOPIS,
                     P.VLDESCREDUCAOCOFINS,
                     P.PERCOM4,
                     P.NUMETIQUETA,
                     P.DTGERACAOOS,
                     P.CODFUNCALTLOTE,
                     P.PRECOFVBRUTO,
                     P.ALTERNATIVO,
                     P.SIGLAQUALIDADE,
                     P.VOLUMEDESEJADO,
                     P.CODBASE,
                     P.CODFORMULA,
                     P.USADEBCREDRCABRIND,
                     P.CODDESCONTO,
                     P.CODCOMBO,
                     P.DTENTREGA,
                     P.MOVIMENTACONTACORRENTERCA,
                     P.IDPATRIMONIO,
                     P.VLREDPVENDASIMPLESNA,
                     P.VLREDCMVSIMPLESNAC,
                     P.PERDESCFOB,
                     P.PRECOMAXCONSUM,
                     P.DESCPRECOFAB,
                     P.ROTINALANCULTALT,
                     P.NUMCAIXA,
                     P.PERCICM,
                     P.CODCONTRATO,
                     P.PRODDESCRICAODANFE,
                     P.IDVENDA,
                     P.PERCDESCINDUSTRIA,
                     P.PERDESCBOLETO,
                     P.CODLINHAPRAZO,
                     NVL(T.ST,0), -->> USAR O VALOR ST DO PEPS
                     NVL(T.ST,0), -->> USAR O VALOR ST DO PEPS
                     P.QTLITRAGEM,
                     P.BONIFIC,
                     P.RP_IMEDIATA,
                     P.GRUPOFATURAMENTO,
                     P.PARTICIPAGIRO,
                     P.QTUN,
                     P.VLIPIOUTRAS,
                     P.PERCIPIOUTRAS,
                     P.VLDESCABATIMENTO,
                     P.PERCDESCABATIMENTO,
                     P.QTRESERVANT,
                     P.VLDESCBOLETO,
                     P.NUMSEQITEMCONTRATO,
                     P.NUMLISTA,
                     P.ROTINALANCBRINDE,
                     P.SUGESTAO,
                     P.CODEMITENTEITEMPEDIDO,
                     P.PERDESCINICOMISS,
                     P.PERDESCFIMCOMISS,
                     P.CONCEDERMAIORCOMISSREG,
                     P.VLSUBTOTITEM,
                     P.PERDESCNEGOCIADO,
                     P.FORMANEGOCIACAO,
                     P.PERDESCAVISTA,
                     P.NEGOCIACAOPOSTERIOR,
                     P.CODPRECOFIXO,
                     P.VLACRESFRETEKG,
                     P.STATUSSUCATA,
                     P.PTABELAAUTPECAS,
                     P.GRPREGRABRINDE,
                     P.NUMITEMPED,
                     P.VLITEMTRIBUTOS,
                     P.PERCTRIBUTOS,
                     P.TOTALIZADORALIQUOTA,
                     P.PERDESCPAUTA,
                     P.ORIGEMST,
                     P.VLDESCSOCIOTORCEDOR,
                     P.QTFALTADIGITACAO,
                     P.VLSALDORCA,
                     P.CODPROMOCAOMED,
                     P.INICIOINTERVALODESCQUANT,
                     P.ALTDESCPROMOCMED,
                     P.NUMRECOPI,
                     P.NUMERORECOPI,
                     P.UNIDADE,
                     P.AMBIENTE,
                     P.TAXACASOMOEDAREAL,
                     P.CODMOEDAESTRAGEIRA,
                     P.VLRMOEDAESTRAGEIRA,
                     P.QTDIASENTREGAITEM,
                     P.DTINICIOPROMOLOTE,
                     P.DTFIMPROMOLOTE,
                     P.PERCIPIECF,
                     P.VLIPIECF,
                     P.BASEIPIECF,
                     P.USAUNIDADEMASTER,
                     P.CLASSEVENDA,
                     P.QT_SEPARADAMANIF,
                     P.LOTECONTRATO,
                     P.PARTICIPACOMISSGARANTIDA,
                     P.CODCONTROLEVASILHAME,
                     P.CODVASILHAMEECF,
                     P.QTSAIDAVASILHAME,
                     P.QTVENDIDAVASILHAME,
                     P.VLACRESCVASILHAME,
                     P.PVENDAVASILHAME,
                     P.CODUSUR2,
                     P.CODUSUR3,
                     P.CODUSUR4,
                     vvRegimeEspIsenStFonte,
                     P.TRANSFERIURCALINHA,
                     T.NUMTRANSPEPS,
                     -- HIS.03371.2017
                     vvIndEscalaRelevante,
                     vvCnpjFabricante,
                     vvFabricante,
                     vrDadosFuncep.nVLBASEFCPICMS,      -- HIS.04200.2017
                     vrDadosFuncep.nVLBASEFCPST,        -- HIS.04200.2017
                     vrDadosFuncep.nVLBCFCPSTRET,       -- HIS.04200.2017
                     vrDadosFuncep.nPERFCPSTRET,        -- HIS.04200.2017
                     vrDadosFuncep.nVLFCPSTRET,         -- HIS.04200.2017
                     vrDadosFuncep.nPERFCPSN,           -- HIS.04200.2017
                     vrDadosFuncep.nVLFECP,             -- HIS.04200.2017
                     vrDadosFuncep.nVLACRESCIMOFUNCEP,  -- HIS.04200.2017
                     vrDadosFuncep.nPERACRESCIMOFUNCEP, -- HIS.04200.2017
                     vrDadosFuncep.nALIQICMSFECP,       -- HIS.04200.2017
                     vrDadosFuncep.nVLCREDFCPICMSSN,    -- HIS.04200.2017                                                                        
                     vrDadosFuncep.nCODCONFIGFUNCEPMED,
                     P.PMPFMEDICAMENTO
              FROM   PCPEDI P
                   , PCPEPSSALDOTEMP T
             WHERE (P.NUMPED        = vc_CabecalhoPedido.NUMPED)
               AND (P.CODPROD       = vrItensPedido.CODPROD)
               AND (NVL(P.NUMSEQ,0) = vrItensPedido.NUMSEQ);
            vnqtregistroatupeps := NVL(SQL%ROWCOUNT,0);   
  
            DELETE FROM PCPEDI
             WHERE (NUMPED        = vc_CabecalhoPedido.NUMPED)
               AND (CODPROD       = vrItensPedido.CODPROD)
               AND (NVL(NUMSEQ,0) = vrItensPedido.NUMSEQ);
            vnqtregistroatupeps := NVL(SQL%ROWCOUNT,0);   
            
          -- Se não tem Registros de PEPS  
          ELSE
          
            -- Atualiza Item
            UPDATE PCPEDI
               SET BASEICST              = vnBaseicst
                 , ST                    = vnSt
                 , PERFRETECMV           = vrValoresCusto.vnperfretecmv
                 , CUSTOFINEST           = vrValoresCusto.vncustofinest
                 , TXVENDA               = vrValoresCusto.vntxvenda
                 , PERDESCCUSTO          = vrValoresCusto.vnperdesccusto
                 , CODICMTAB             = vrValoresCusto.vncodicmtab
                 , VLCUSTOFIN            = vrValoresCusto.vnvlcustofin
                 , VLCUSTOREAL           = vrValoresCusto.vnvlcustoreal
                 , VLDESCCUSTOCMV        = vrValoresCusto.vnvldesccustocmv
                   --
                   -- OBSERVAÇÃO: Passou a ser somado o ST do FUNCEP - PCPEDI.VLFECP - HIS.04200.2017
                   -- DDMEDICA-7584 - Descontado o Somatório dos valores unitários dos benefícios fiscais ao invés de somente a desoneração de ICMS
                   -- DDMEDICA-7697 - Somado o ST Antecipado
                 , PVENDA               = ROUND((NVL(vnPrecoLiqOriginal,0)     
                                                + NVL(vnSt,0) 
                                                + NVL(vrDadosStAntecip.nVLICMSSTRETANTERIOR,0) 
                                                + NVL(vnVlRepasse,0) 
                                                + NVL(PCPEDI.VLIPI,0) 
                                                + NVL(vrDadosFuncep.nVLFECP,0) 
                                                - NVL(vnVlSomaDescUnitBenefFiscais,0)), vrParametros.vnNumCasasDecVenda) -- MED-900 - Arredondar
                 , PTABELA              = ROUND((NVL(vnPrecoTabOriginal,0)     
                                                + NVL(vnSt,0) 
                                                + NVL(vrDadosStAntecip.nVLICMSSTRETANTERIOR,0) 
                                                + NVL(vnVlRepasse,0) 
                                                + NVL(PCPEDI.VLIPI,0) 
                                                + NVL(vrDadosFuncep.nVLFECP,0) 
                                                - NVL(vnVlSomaDescUnitBenefFiscais,0)), vrParametros.vnNumCasasDecVenda) -- MED-900 - Arredondar
                 , PBASERCA             = ROUND((NVL(vnPrecoBaseRcaOriginal,0) 
                                                + NVL(vnSt,0) 
                                                + NVL(vrDadosStAntecip.nVLICMSSTRETANTERIOR,0) 
                                                + NVL(vnVlRepasse,0) 
                                                + NVL(PCPEDI.VLIPI,0) 
                                                + NVL(vrDadosFuncep.nVLFECP,0) 
                                                - NVL(vnVlSomaDescUnitBenefFiscais,0)), vrParametros.vnNumCasasDecVenda) -- MED-900 - Arredondar
                 , STPBASERCA           = NVL(vnSt,0)
                 , STPTABELA            = NVL(vnSt,0)
                 , REGIMEESPISENSTFONTE = vvRegimeEspIsenStFonte
                 , ALIQICMS1            = vnAliqIcms1
                 , ALIQICMS2            = vnAliqIcms2
                 , IVA                  = vnIva
                 , PERCBASEREDSTFONTE   = vnPercBaseRedStFonte
                 --
                 , VLREPASSE            = NVL(vnVlRepasse,0)
                 , VLOUTROS             = NVL(vnVlOutros,0)
                 , PORIGINAL            = NVL(vnPOriginal,0)
                 -- MED-656 - Atualização do PBONIFIC - Item Bonificado
                 , PBONIFIC             = ROUND((DECODE(NVL(BONIFIC,'N'),
                                                 'F', NVL(vnPrecoLiqOriginal,0) + NVL(vnSt,0) + NVL(vnVlRepasse,0) + NVL(PCPEDI.VLIPI,0) + NVL(vrDadosFuncep.nVLFECP,0)
                                                    , PBONIFIC)),vrParametros.vnNumCasasDecVenda) -- MED-900 - Arredondar
                 --
                 , QTDEDOACAOPEDLICIT   = vrItensPedido.QTDEDOACAOPEDLICIT -- 6803.037246.2017
                 -- 
                 , PAUTA                = vnPautaFonte
                 , OBSERVACAOSTFONTE    = SUBSTR('Rec:' || vvObservacaoStFonte,1,2000) -- HIS.01838.2017
                 -- HIS.03371.2017
                 , INDESCALARELEVANTE   = vvIndEscalaRelevante
                 , CNPJFABRICANTE       = vvCnpjFabricante
                 , FABRICANTE           = vvFabricante               
                 , VLBASEFCPICMS        = vrDadosFuncep.nVLBASEFCPICMS       -- HIS.04200.2017
                 , VLBASEFCPST          = vrDadosFuncep.nVLBASEFCPST         -- HIS.04200.2017
                 , VLBCFCPSTRET         = vrDadosFuncep.nVLBCFCPSTRET        -- HIS.04200.2017
                 , PERFCPSTRET          = vrDadosFuncep.nPERFCPSTRET         -- HIS.04200.2017
                 , VLFCPSTRET           = vrDadosFuncep.nVLFCPSTRET          -- HIS.04200.2017
                 , PERFCPSN             = vrDadosFuncep.nPERFCPSN            -- HIS.04200.2017
                 , VLFECP               = vrDadosFuncep.nVLFECP              -- HIS.04200.2017
                 , VLACRESCIMOFUNCEP    = vrDadosFuncep.nVLACRESCIMOFUNCEP   -- HIS.04200.2017
                 , PERACRESCIMOFUNCEP   = vrDadosFuncep.nPERACRESCIMOFUNCEP  -- HIS.04200.2017
                 , ALIQICMSFECP         = vrDadosFuncep.nALIQICMSFECP        -- HIS.04200.2017
                 , VLCREDFCPICMSSN      = vrDadosFuncep.nVLCREDFCPICMSSN     -- HIS.04200.2017                                                   
                 , CODCONFIGFUNCEPMED   = vrDadosFuncep.nCODCONFIGFUNCEPMED   
                 , PMPFMEDICAMENTO      = vnPmPfMedicamento
                 -- DDMEDICA-7697
                 , BCSTRETANTERIOR          = vrDadosStAntecip.nBCSTRETANTERIOR
                 , VLICMSSUBSTITUTOANTERIOR = vrDadosStAntecip.nVLICMSSUBSTITUTOANTERIOR
                 , VLICMSSTRETANTERIOR      = vrDadosStAntecip.nVLICMSSTRETANTERIOR                                            
                 , STCLIENTEGNRE            = vnStClienteGnre
             WHERE (NUMPED        = vc_CabecalhoPedido.NUMPED)
               AND (CODPROD       = vrItensPedido.CODPROD)
               AND (NVL(NUMSEQ,0) = vrItensPedido.NUMSEQ);
              
            ----------------------------------------------------   
            -- Se Desoneração da Licitação - 6803.037246.2017 --
            ----------------------------------------------------
            IF (NVL(pi_vCalculaDesoneracaoLicit,'N') = 'S') AND
               (NVL(vc_CabecalhoPedido.CODEDITAL,0) > 0)    THEN
  
              -- Sql de Consulta do Item do Edital
              vvSqlDesoneracaoIcms := ' SELECT PCEDITAISITENS.LICITUSARDESONERAICM ' ||
                                      '      , PCEDITAISITENS.LICITPERCDESONERAICM ' ||
                                      '   FROM PCEDITAISITENS                      ' ||
                                      '  WHERE (PCEDITAISITENS.CODEDITAL   =       ' || NVL(NVL(vrItensPedido.CODEDITAL,vc_CabecalhoPedido.CODEDITAL),0) || ')' ||
                                      '    AND (PCEDITAISITENS.LOTE        =       ' || '''' || vrItensPedido.LOTECONTRATO              || ''''          || ')' ||
                                      '    AND (PCEDITAISITENS.NUMERO_ITEM =       ' || '''' || NVL(vrItensPedido.NUMSEQITEMCONTRATO,0) || ''''          || ')';
  
              -- Busca Dados da Desoneração da Licitação
              BEGIN
                EXECUTE IMMEDIATE vvSqlDesoneracaoIcms
                             INTO vrDadosItemEdital;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  vrDadosItemEdital := vrLimpaDadosItemEdital;
                WHEN OTHERS THEN
                  vrDadosItemEdital := vrLimpaDadosItemEdital;
              END;
              
              -- Calcula a Desoneração
              IF (NVL(vrDadosItemEdital.vvUsarDesoneraIcm,'N') = 'S') THEN
                nVLDESCICMISENCAO  := (NVL(vnPrecoLiqOriginal,0) * (NVL(vrDadosItemEdital.vnPercDesoneraIcm,0) / 100));
                nPERDESCISENTOICMS := NVL(vrDadosItemEdital.vnPercDesoneraIcm,0);
              ELSE
                nVLDESCICMISENCAO  := 0;
                nPERDESCISENTOICMS := 0;
              END IF;                       
  
              -- Atualiza Item
              UPDATE PCPEDI
                 SET VLDESCICMISENCAO  = nVLDESCICMISENCAO
                   , PERDESCISENTOICMS = nPERDESCISENTOICMS
               WHERE (NUMPED        = vc_CabecalhoPedido.NUMPED)
                 AND (CODPROD       = vrItensPedido.CODPROD)
                 AND (NVL(NUMSEQ,0) = vrItensPedido.NUMSEQ);
  
            END IF; -- Fim Condição: Se Desoneração da Licitação
                         
          END IF; -- Fim Condição: Se Tem Registros de PEPS
  
        END LOOP; -- Fim Processamento do Array de Itens do Pedido
      END IF;
      
      -- Recalculo do cabecalho do pedido
      SELECT SUM(DECODE(PCPEDC.CONDVENDA,
                        4,
                        0,
                        5,
                        0,
                        8,
                        0,
                        11,
                        0,
                        NVL(PCPEDI.QT, 0) * NVL(PCPEDI.PVENDA, 0))) VLATEND
           , SUM(DECODE(PCPEDC.CONDVENDA,
                        4,
                        0,
                        7,
                        0,
                        NVL(PCPEDI.QT, 0) * NVL(PCPEDI.PTABELA, 0))) VLTABELA
           , SUM((NVL(PCPEDI.QT, 0) + NVL(PCPEDI.QTFALTA, 0)) * NVL(PCPEDI.PVENDA, 0)) VLTOTAL
           , SUM(NVL(PCPEDI.QT, 0) * NVL(PCPEDI.VLCUSTOFIN, 0)) VLCUSTOFIN -- 5666.044130.2018
        INTO vnVlAtend
           , vnVlTabela
           , vnVlTotal 
           , vnVlCustoFin -- 5666.044130.2018
        FROM PCPEDI
           , PCPEDC
       WHERE (PCPEDI.NUMPED = PCPEDC.NUMPED)
         AND (PCPEDC.NUMPED = vc_CabecalhoPedido.NUMPED);
         
      -- Totais BNF em TV1
      SELECT SUM(PBONIFIC * QT)
        INTO vnvlbnftv1
        FROM PCPEDI
       WHERE NUMPED  = vc_CabecalhoPedido.NUMPED
         AND BONIFIC = 'F';       
  
      vnVlAtend  := ROUND(NVL(vnVlAtend,0)  + NVL(vc_CabecalhoPedido.VLOUTRASDESP,0) + NVL(vc_CabecalhoPedido.VLFRETE,0) - NVL(vc_CabecalhoPedido.VLDESCONTO,0) -
                          nvl(vnvlbnftv1,0), 2);
      vnVlTabela := ROUND(NVL(vnVlTabela,0) + NVL(vc_CabecalhoPedido.VLOUTRASDESP,0) + NVL(vc_CabecalhoPedido.VLFRETE,0) - NVL(vc_CabecalhoPedido.VLDESCONTO,0),2);
      vnVlTotal  := ROUND(NVL(vnVlTotal,0)  + NVL(vc_CabecalhoPedido.VLOUTRASDESP,0) + NVL(vc_CabecalhoPedido.VLFRETE,0) - NVL(vc_CabecalhoPedido.VLDESCONTO,0),2);
  
      IF (vc_CabecalhoPedido.CONDVENDA IN (4, 7)) THEN
        vnVlTabela := 0;
      END IF;
  
      IF (vc_CabecalhoPedido.CONDVENDA IN (4, 5, 8, 11)) THEN
        vnVlAtend := 0;
      END IF;
      
      -- Atualiza Total do Pedido
      UPDATE PCPEDC
         SET VLATEND  = NVL(vnVlAtend,0)
           , VLTABELA = NVL(vnVlTabela,0)
           , VLTOTAL  = NVL(vnVlTotal,0)
           , VLCUSTOFIN = NVL(vnVlCustoFin,0) -- 5666.044130.2018
       WHERE (NUMPED = vc_CabecalhoPedido.NUMPED);
       
      -- Totais BNF em TV1
      IF (NVL(vnvlbnftv1,0) > 0) THEN
        UPDATE pcpedc
           SET vlbonific = vnvlbnftv1
         WHERE numped = vc_CabecalhoPedido.NUMPED;
      END IF;         
                               
    END LOOP; -- Fim Cursor de Dados do Pedido
        
  EXCEPTION
    WHEN e_CalcularStFonte THEN
      ROLLBACK;
      po_vOcorreramErros := 'S'; 
      pi_vvMsgErros      := vvMsgRetObterStFonte;
    WHEN OTHERS THEN
      ROLLBACK;
      po_vOcorreramErros := 'S'; 
      pi_vvMsgErros      := 'Erro Geral Cálculo ST: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ' >> ' || SQLERRM;
  END P_RECALCULAR_STFONTE;

 /*******************************************************************************
  Nome         : P_CALC_RED_SIMPLES_NAC
  Descrição    : Procedimento para calcular a Recução do Simples Nacional 
                 *** Somente para Clientes Fonte ***
  Parâmetros   : ENTRADA:
                 psCodFilial              = CÃ³digo da Filial
                 pCodCli                  = CÃ³digo do Cliente
                 pCodProd                 = CÃ³digo do Produto
                 pCondVenda               = Tipo de Venda
                 pPreco                   = PreÃ§o Liquido
                 pPrecoTabela             = PreÃ§o Tabela
                 pValorIpi                = Valor do IPI
                 pPrecoMaxConsum          = PreÃ§o MÃ¡ximo do Consumidor
                 SAIDA:
                 po_vTipoRedSimplesNac          = Tipo de ReduÃ§Ã£o do Simples Nacional
                                                  P - ReduÃ§Ã£o no PreÃ§o
                                                  S - ReduÃ§Ã£o no ST
                 po_nPercRedSimplesNac          = Percentual de ReduÃ§Ã£o do Simples Nacional
                 po_nValorRedSimplesNac         = Valor da ReduÃ§Ã£o do Simples Nacional
                 po_ValorRedSimplesNacNoPreco   = Valor da ReduÃ§Ã£o do Simples Nacional a
                                                  Reduzir no PreÃ§o
                 po_ValorRedSimplesNacNoStFonte = Valor da ReduÃ§Ã£o do Simples Nacional a
                                                  Reduzir no ST Fonte
                 po_vOcorreramErros             = Se ocorreram Erros (S/N)
                 po_vMsgErros                   = Mensagem de Erros
  AlteracÃ£o    : Anderson Silva - 08/01/2015 - CriaÃ§Ã£o da Procedure [HIS.05161.2014]
  AlteracÃ£o    : Anderson Silva - 21/01/2015 - ParÃ¢metros ST do Cliente por Filial
  AlteracÃ£o    : Anderson Silva - 26/01/2015 - CAT CMED [HIS.00021.2015]
                                               Regime IsenÃ§Ã£o [HIS.04991.2014]
  AlteraÃ§Ã£o    : Anderson Silva - 26/01/2015 - 3826.054937.2015 - Somente criticar Cliente ST fonte
                                                                  se cliente calcula st da precificaÃ§Ã£o
 
  OBSERVAÃ‡ÃƒO:
  ----------
  Duas Formas de calcular o Valor da ReduÃ§Ã£o do Simples Nacional, sendo uma delas dividida
  em duas operaÃ§Ãµes:
  1) Desconto no PreÃ§o de Venda 
     Quando na 132 UsaDescSimplesNac = 'S', aplica PCTRIBUT.PERCDESCSIMPLESNAC no PreÃ§o de Venda para obter o valor da reduÃ§Ã£o
  2) ReduÃ§Ã£o no PreÃ§o de Venda
     Quando na 132 UsaDescSimplesNac = 'N' e PCTRIBUT.PERCREDPVENDASIMPLESNAC <> 0,
     2.1) Sem IVA, Sem Pauta, *** PMC *** e Aliq2 >= Aliq1
          Realiza cÃ¡lculo com base nos valores da Ãºltima entrada para obter o valor da reduÃ§Ã£o
     2.2) Demais casos
          Realiza o cÃ¡lculo do ST sem ReduÃ§Ã£o do IVA e com ReduÃ§Ã£o do IVA, a diferenÃ§a entre os dois ST serÃ¡ o valor da reduÃ§Ã£o
  ********************************************************************************/                                       
  PROCEDURE P_CALC_RED_SIMPLES_NAC(psCodFilial                    IN  VARCHAR2,
                                   pCodCli                        IN  NUMBER,
                                   pCodProd                       IN  NUMBER,
                                   pCondVenda                     IN  NUMBER,
                                   pPreco                         IN  NUMBER,
                                   pPrecoTabela                   IN  NUMBER,
                                   pValorIpi                      IN  NUMBER,
                                   pPrecoMaxConsum                IN  NUMBER,
                                   pTipoMerc                      IN  VARCHAR2,
                                   pi_vCodFilialNf                IN  VARCHAR2,
                                   po_vTipoRedSimplesNac          OUT VARCHAR2,
                                   po_nPercRedSimplesNac          OUT NUMBER,
                                   po_nValorRedSimplesNac         OUT NUMBER,
                                   po_ValorRedSimplesNacNoPreco   OUT NUMBER,
                                   po_ValorRedSimplesNacNoStFonte OUT NUMBER,
                                   po_vOcorreramErros             OUT VARCHAR2,
                                   po_vMsgErros                   OUT VARCHAR2,
                                   pi_nNumRegiaoEnt               IN  NUMBER DEFAULT NULL,   -- DDVENDAS-33718
                                   pi_vEstEnt                     IN  VARCHAR2 DEFAULT NULL) -- DDVENDAS-33718
 IS
 
   /***********************
    DeclaraÃ§Ã£o de VariÃ¡veis
    ***********************/
    
    -- Base do ST 1
    vnBaseSt1                     PCPEDI.BASEICST%TYPE;
    vvRegimeEspIsenStFonte1       PCTRIBUT.REGIMEESPISENSTFONTE%TYPE;
    vnAliqIcms11                  PCPEDI.ALIQICMS1%TYPE;
    vnAliqIcms21                  PCPEDI.ALIQICMS2%TYPE;
    vnIva1                        PCPEDI.IVA%TYPE;
    vnPercBaseRedStFonte1         PCPEDI.PERCBASEREDSTFONTE%TYPE;
    -- Base ST 2
    vnBaseSt2                     PCPEDI.BASEICST%TYPE;
    vvRegimeEspIsenStFonte2       PCTRIBUT.REGIMEESPISENSTFONTE%TYPE;
    vnAliqIcms12                  PCPEDI.ALIQICMS1%TYPE;
    vnAliqIcms22                  PCPEDI.ALIQICMS2%TYPE;
    vnIva2                        PCPEDI.IVA%TYPE;
    vnPercBaseRedStFonte2         PCPEDI.PERCBASEREDSTFONTE%TYPE;
    -- Mensagem Proc. de Obter ST Fonte
    vvMsgErros_ObtemStFonte       VARCHAR2(240);
  
    -- Tipo Record de ParÃ¢metros da Filial
    TYPE TRec_ParamFilial         IS RECORD(
         TratarRestricaoAcrescimo PCCONSUM.TRATARRESTRICAOACRESCIMO%TYPE,
         NumCasasDecimais         PCCONSUM.NUMCASASDECVENDA%TYPE,
         UsaTributacaoPorUF       pcconsum.usatributacaoporuf%TYPE,
         TipoAliqoutrasdesp       pcconsum.tipoaliqoutrasdesp%TYPE,
         AliqIcmoutrasdesp        pcconsum.aliqicmoutrasdesp%TYPE,
         AliqIcminteroutrasdesp   pcconsum.Aliqicminteroutrasdesp%TYPE,
         CalcSTpf                 pcconsum.calcstpf%TYPE,
         ConsideraIsentoscomopf   pcconsum.consideraisentoscomopf%TYPE,
         TxVenda                  pcconsum.txvenda%TYPE,
         Tipocalcst               pcconsum.tipocalcst%TYPE,
         PercicmFrete             pcconsum.percicmfrete%TYPE,
         PercIcminterfrete        pcconsum.percicminterfrete%TYPE,
         MostrarPvendasemst       pcconsum.mostrarpvendasemst%TYPE,
         CalcularIPIVenda         VARCHAR2(5),
         CalcularSTComIPI         VARCHAR2(5),
         RetiraIpiPedidoTV8       VARCHAR2(5),
         AceitaPFContribuinte     VARCHAR2(5),
         UtilizaPercBaseredPF     VARCHAR2(5),
         UsaDescSimplesNac        VARCHAR2(5),
         UsarTributacaoTransfTV10 VARCHAR2(5)
         );
  
    -- Tipo Record de Dados da RegiÃ£o
    TYPE TRec_Regiao              IS RECORD (
         NumRegiao                PCREGIAO.NUMREGIAO%TYPE
    );
  
    -- Tipo Record de Dados da PCEST
    TYPE TRec_Estoque             IS RECORD (
         CodFilial                PCEST.codfilial%TYPE,
         CodProd                  PCEST.Codprod%TYPE,
         VALORULTENT              PCEST.VLULTPCOMPRA%TYPE,
         VLSTULTENT               PCEST.VLSTULTENT%TYPE,
         VLSTGUIAULTENT           PCEST.VLSTGUIAULTENT%TYPE,
         IVAULTENT                PCEST.IVAULTENT%TYPE,
         ALIQICMS1ULTENT          PCEST.ALIQICMS1ULTENT%TYPE,
         ALIQICMS2ULTENT          PCEST.ALIQICMS2ULTENT%TYPE,
         REDBASEIVAULTENT         PCEST.REDBASEIVAULTENT%TYPE,
         PERCICMSFRETEFOBSTULTENT PCEST.PERCICMSFRETEFOBSTULTENT%TYPE,
         VLFRETECONHECULTENT      PCEST.VLFRETECONHECULTENT%TYPE,
         PERCALIQEXTGUIAULTENT    PCEST.PERCALIQEXTGUIAULTENT%TYPE,
         BASEICMSULTENT           PCEST.BASEICMSULTENT%TYPE ,
         CUSTONFSEMST             PCEST.CUSTONFSEMST%TYPE,
         CUSTONFSEMSTGUIAULTENT   PCEST.CUSTONFSEMSTGUIAULTENT%TYPE,
         PERCMVAORIGULTENT        PCEST.PERCMVAORIGULTENT%TYPE
    );
   
    -- Record de InformaÃ§Ãµes para CÃ¡lculo do Imposto
    TYPE TRec_Imposto                 IS RECORD(
         Cliente                      PCCLIENT%ROWTYPE,
         Produto                      PCPRODUT%ROWTYPE,
         Precificacao                 PCTABPR%ROWTYPE,
         Tributacao                   PCTRIBUT%ROWTYPE,
         Estoque                      PCEST%ROWTYPE,
         Filial                       PCFILIAL%ROWTYPE,
         Parametros132                TRec_ParamFilial,
         Regiao                       TRec_Regiao);
    Imposto                           TRec_Imposto;
    
    -- VariÃ¡veis Auxiliares - REGRA PACOTE
    vnPercentualdeRedSimplesNac       pctribut.percredpvendasimplesnac%TYPE;
    vnPercentualdeReducaoBaseIVA      pcest.REDBASEIVAULTENT%TYPE;
    vnST1                             NUMBER(18,8);
    vnST2                             NUMBER(18,8);
    vnST                              NUMBER(18,8);
    vnST_Guia                         NUMBER(18,8);
    vnST1_Guia                        NUMBER(18,8);
    vnST2_Guia                        NUMBER(18,8);
    vnVlReducao                       NUMBER(18,8);
    vnVlReducao1                      NUMBER(18,8);
    vnVlReducao2                      NUMBER(18,8);
    vnPercRedSimplesNasc              NUMBER(18,8); 
    vnFatorAjuste                     NUMBER;
    vnFatorAjusteGuia                 NUMBER;
    
    -- DDMEDICA-3639 - Simples Nacional ST Fonte na Integradora 
    vnPautaFonte                      PCPEDI.PAUTA%TYPE;
    vvObservacaoStFonte               PCPEDI.OBSERVACAOSTFONTE%TYPE;
    vvIndEscalaRelevante              PCPEDI.INDESCALARELEVANTE%TYPE;
    vvCnpjFabricante                  PCPEDI.CNPJFABRICANTE%TYPE;
    vvFabricante                      PCPEDI.FABRICANTE%TYPE;
    -- Dados dos Itens do Funcep - DDMEDICA-3639
    TYPE TRecDadosFuncep               IS RECORD(
         nVLBASEFCPICMS                PCPEDI.VLBASEFCPICMS%TYPE,
         nVLBASEFCPST                  PCPEDI.VLBASEFCPST%TYPE,
         nVLBCFCPSTRET                 PCPEDI.VLBCFCPSTRET%TYPE,
         nPERFCPSTRET                  PCPEDI.PERFCPSTRET%TYPE,
         nVLFCPSTRET                   PCPEDI.VLFCPSTRET%TYPE,
         nPERFCPSN                     PCPEDI.PERFCPSN%TYPE,
         nVLFECP                       PCPEDI.VLFECP%TYPE,
         nVLACRESCIMOFUNCEP            PCPEDI.VLACRESCIMOFUNCEP%TYPE,
         nPERACRESCIMOFUNCEP           PCPEDI.PERACRESCIMOFUNCEP%TYPE,
         nALIQICMSFECP                 PCPEDI.ALIQICMSFECP%TYPE,
         nVLCREDFCPICMSSN              PCPEDI.VLCREDFCPICMSSN%TYPE,
         nCODCONFIGFUNCEPMED           PCPEDI.CODCONFIGFUNCEPMED%TYPE,
         nVLDESCICMISENCAO             PCPEDI.VLDESCICMISENCAO%TYPE
         );
    vrDadosFuncep                      TRecDadosFuncep;
    
    -- Parâmetro Específico Simples Nacional
    v_medutilizarstfontesimplesnac     PCREGRASEXCECAOMED.VALOR%TYPE;
    
    -- Exceções
    e_Tratado                          EXCEPTION;
    
   /********************************************************************
    Procedure: P_INICIALIZAR_INF_IMPOSTO
    DescriÃ§Ã£o: Inicializar Record de InformaÃ§Ãµes para CÃ¡lculo do Imposto
    ********************************************************************/
    PROCEDURE P_INICIALIZAR_INF_IMPOSTO(pi_nCodCli          IN NUMBER,
                                        pi_nCodProd         IN NUMBER,
                                        pi_vCodFilial       IN NUMBER,
                                        pio_vOcorreramErros IN OUT VARCHAR2,
                                        pio_vMsgErros       IN OUT VARCHAR2) IS
                       
      -- CÃ³digo da TributaÃ§Ã£o
      vnCodSt PCTRIBUT.CODST%TYPE;   
     
      ---------------------------------------------------- 
      -- Procedimento para Retornar o CÃ³digo da TributaÃ§Ã£o
      ----------------------------------------------------
      PROCEDURE P_RETORNA_CODIGO_TRIBUTACAO(pi_nCodProd            IN     NUMBER,
                                            pi_nCodCli             IN     NUMBER,
                                            pi_nNumRegiao          IN     NUMBER,
                                            pi_vUfCli              IN     VARCHAR2,
                                            pi_vCodFilial          IN     VARCHAR2,
                                            pi_vUsaTributacaoPorUF IN     VARCHAR2,
                                            po_nCodSt              OUT    NUMBER,
                                            pio_vOcorreramErros    IN OUT VARCHAR2,
                                            pio_vMsgErros          IN OUT VARCHAR2) IS  
      BEGIN
          
        -- Inicializa Retorno
        po_nCodSt := NULL;
        
        -- Se Usa TributaÃ§Ã£o por UF
        IF (NVL(pi_vUsaTributacaoPorUF,'N') = 'S') THEN
          
          -- Pesquisa TributaÃ§Ã£o por UF
          BEGIN      
            SELECT PCTABTRIB.CODST
              INTO po_nCodSt
              FROM PCTABTRIB
             WHERE (PCTABTRIB.CODPROD     = pi_nCodProd)
               AND (PCTABTRIB.UFDESTINO   = pi_vUfCli)
               AND (PCTABTRIB.CODFILIALNF = pi_vCodFilial);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              pio_vOcorreramErros := 'S';
              pio_vMsgErros       := pio_vMsgErros || CHR(13);
              pio_vMsgErros       := pio_vMsgErros || 'TributaÃ§Ã£o nÃ£o encontrada para o Produto: ' || NVL(pi_nCodProd,0) || ' UF Destino ' || NVL(pi_vUfCli,' ') || ' e Filial ' || NVL(pi_vCodFilial,' ');
          END;             
    
        -- Se Usa TributaÃ§Ã£o por RegiÃ£o
        ELSE
              
          -- Pesquisa TributaÃ§Ã£o por RegiÃ£o
          BEGIN      
            SELECT PCTABPR.CODST
              INTO po_nCodSt
              FROM PCTABPR
             WHERE (PCTABPR.CODPROD   = pi_nCodProd)
               AND (PCTABPR.NUMREGIAO = pi_nNumRegiao);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              pio_vOcorreramErros := 'S';
              pio_vMsgErros       := pio_vMsgErros || CHR(13);
              pio_vMsgErros       := pio_vMsgErros || 'TributaÃ§Ã£o nÃ£o encontrada para o Produto: ' || NVL(pi_nCodProd,0) || ' e RegiÃ£o ' || NVL(pi_nNumRegiao,0);
          END;             
        END IF;
          
      END P_RETORNA_CODIGO_TRIBUTACAO;
                                     
    ---------------------------------------------------
    -- Inicio do Procedimento P_INICIALIZAR_INF_IMPOSTO
    ---------------------------------------------------
    BEGIN
    
      -- Inicio do Processamento
      po_nPercRedSimplesNac  := 0;
      po_nValorRedSimplesNac := 0;
      
      -- Pesquisa ParÃ¢metros da 132
      Imposto.Parametros132.UsaDescSimplesNac        := F_BUSCARPARAMETRO_ALFA('USADESCSIMPLESNAC',psCodFilial,'S');
      Imposto.Parametros132.usaTributacaoPorUF       := F_BUSCARPARAMETRO_ALFA('CON_USATRIBUTACAOPORUF','99','N');
      Imposto.Parametros132.tipoaliqoutrasdesp       := F_BUSCARPARAMETRO_ALFA('CON_TIPOALIQOUTRASDESP','99','P');
      Imposto.Parametros132.aliqicmoutrasdesp        := F_BUSCARPARAMETRO_NUM('CON_ALIQICMOUTRASDESP','99',0);
      Imposto.Parametros132.aliqicminteroutrasdesp   := F_BUSCARPARAMETRO_NUM('CON_ALIQICMINTEROUTRASDESP','99',0);
      Imposto.Parametros132.calcstpf                 := F_BUSCARPARAMETRO_ALFA('CON_CALCSTPF','99','S');
      Imposto.Parametros132.consideraisentoscomopf   := F_BUSCARPARAMETRO_ALFA('CON_CONSIDERAISENTOSCOMOPF','99','N');
      Imposto.Parametros132.UtilizaPercBaseredPF     := F_BUSCARPARAMETRO_ALFA('CON_UTILIZAPERCBASEREDPF','99','N');
      Imposto.Parametros132.AceitaPFContribuinte     := F_BUSCARPARAMETRO_ALFA('CON_ACEITAPFCONTRIBUINTE','99','N');
      Imposto.Parametros132.txvenda                  := F_BUSCARPARAMETRO_NUM('CON_TXVENDA','99',0);
      Imposto.Parametros132.tipocalcst               := F_BUSCARPARAMETRO_ALFA('CON_TIPOCALCST','99','PV');
      Imposto.Parametros132.percicmfrete             := F_BUSCARPARAMETRO_NUM('CON_PERCICMFRETE','99',0);
      Imposto.Parametros132.percicminterfrete        := F_BUSCARPARAMETRO_NUM('CON_PERCICMINTERFRETE','99',0);
      Imposto.Parametros132.mostrarpvendasemst       := F_BUSCARPARAMETRO_ALFA('CON_MOSTRARPVENDASEMST','99','N');
      Imposto.Parametros132.usaTributacaoPorUF       := F_BUSCARPARAMETRO_ALFA('CON_USATRIBUTACAOPORUF','99','N');
      Imposto.Parametros132.UsarTributacaoTransfTV10 := F_BUSCARPARAMETRO_ALFA('CON_USARTRIBUTACAOTRANSFTV10','99','N');
    
      -- Pesquisa Dados do Cliente
      BEGIN
        SELECT PCCLIENT.*
          INTO Imposto.Cliente
          FROM PCCLIENT
         WHERE (PCCLIENT.CODCLI = pi_nCodCli);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          pio_vOcorreramErros := 'S';
          pio_vMsgErros       := pio_vMsgErros || CHR(13);
          pio_vMsgErros       := pio_vMsgErros || 'Dados nÃ£o encontrados para o Cliente: ' || NVL(pi_nCodCli,0);
      END;
      
      -- DDVENDAS-33718 - UF de Entrega do Cliente
      IF (pi_vEstEnt IS NOT NULL) THEN
        Imposto.Cliente.EstEnt := pi_vEstEnt;
      END IF;
  
      -- Pesquisa Dados do Cliente por Filial
      BEGIN
        SELECT NVL(PCCLIENTFILIALMED.CLIENTEFONTEST,'N')
          INTO Imposto.Cliente.ClienteFonteSt
          FROM PCCLIENTFILIALMED
         WHERE (PCCLIENTFILIALMED.CODCLI    = pi_nCodCli)
           AND (PCCLIENTFILIALMED.CODFILIAL = pi_vCodFilial);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -->> Se nÃ£o encontrar exceÃ§Ã£o por Filial, MantÃ©m os valores da PCCLIENT
          NULL;
      END;
    
      -- Pesquisa NÃºmero da RegiÃ£o
      BEGIN
        SELECT PCTABPRCLI.NUMREGIAO
          INTO Imposto.Regiao.NumRegiao
          FROM PCTABPRCLI
         WHERE (PCTABPRCLI.CODCLI      = pi_nCodCli)
           AND (PCTABPRCLI.CODFILIALNF = pi_vCodFilial);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- NÃ£o existindo RegiÃ£o por Filial, busca RegiÃ£o da PraÃ§a
          BEGIN
            SELECT PCPRACA.NUMREGIAO
              INTO Imposto.Regiao.NumRegiao
              FROM PCPRACA
             WHERE (PCPRACA.CODPRACA = Imposto.Cliente.CodPraca);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              pio_vOcorreramErros := 'S';
              pio_vMsgErros       := pio_vMsgErros || CHR(13);
              pio_vMsgErros       := pio_vMsgErros || 'Dados nÃ£o encontrados para a PraÃ§a: ' || NVL(Imposto.Cliente.CodPraca,0);
          END;
      END;
      
      -- DDVENDAS-33718 - Região de Entrega do Cliente
      IF (NVL(pi_nNumRegiaoEnt,0) > 0) THEN
        Imposto.Regiao.NumRegiao := pi_nNumRegiaoEnt;
      END IF;      
  
      -- Pesquisa Dados do Produto
      BEGIN
        SELECT PCPRODUT.*
          INTO Imposto.Produto
          FROM PCPRODUT
         WHERE (PCPRODUT.CODPROD = pi_nCodProd);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          pio_vOcorreramErros := 'S';
          pio_vMsgErros       := pio_vMsgErros || CHR(13);
          pio_vMsgErros       := pio_vMsgErros || 'Dados nÃ£o encontrados para o Produto: ' || NVL(pi_nCodProd,0);
      END;
  
      -- Procedimento para Retornar o CÃ³digo da TributaÃ§Ã£o
      P_RETORNA_CODIGO_TRIBUTACAO(pi_nCodProd,
                                  pi_nCodCli,
                                  Imposto.Regiao.NumRegiao,
                                  Imposto.Cliente.EstEnt,
                                  pi_vCodFilial,
                                  Imposto.Parametros132.usaTributacaoPorUF,
                                  vnCodSt, -->> RETORNO com o CÃ³digo da TributaÃ§Ã£o
                                  pio_vOcorreramErros,
                                  pio_vMsgErros);
      
      -- Pesquisa Dados da Filial
      BEGIN
        SELECT PCFILIAL.*
          INTO Imposto.Filial
          FROM PCFILIAL
         WHERE (PCFILIAL.CODIGO = pi_vCodFilial);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          pio_vOcorreramErros := 'S';
          pio_vMsgErros       := pio_vMsgErros || CHR(13);
          pio_vMsgErros       := pio_vMsgErros || 'Dados nÃ£o encontrados para a Filial: ' || NVL(pi_vCodFilial,' ');
      END;
  
      -- Pesquisa Dados da TributaÃ§Ã£o
      BEGIN
        SELECT PCTRIBUT.*
          INTO Imposto.Tributacao
          FROM PCTRIBUT
         WHERE (PCTRIBUT.CODST   = vnCodSt);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          pio_vOcorreramErros := 'S';
          pio_vMsgErros       := pio_vMsgErros || CHR(13);
          pio_vMsgErros       := pio_vMsgErros || 'Dados nÃ£o encontrados para a TributaÃ§Ã£o: ' || NVL(vnCodSt,0);
      END;
   
      --------------------------------------------------------------------   
      -- CLIENTE FONTE ST - REPLICAR ALIQUOTAS PARA USO NA REGRA DO PACOTE
      -- DDMEDICA-3639 - Aplicar NVL
      --------------------------------------------------------------------   
      Imposto.Tributacao.AliqIcms1 := NVL(Imposto.Tributacao.AliqIcms1Fonte,0);
      Imposto.Tributacao.AliqIcms2 := NVL(Imposto.Tributacao.AliqIcms2Fonte,0);
      Imposto.Tributacao.Iva       := NVL(Imposto.Tributacao.IvaFonte,0);
      Imposto.Tributacao.pauta     := NVL(Imposto.Tributacao.PautaFonte,0);
 
      --------------------------------------------------------------------   
      -- Se Cliente for SIMPLES Nacional - DDMEDICA-3639
      IF (NVL(Imposto.Cliente.SimplesNacional,'N') = 'S') THEN
        BEGIN   
          -- Busca Parâmetro
          SELECT NVL(VALOR,'N')         
            INTO v_medutilizarstfontesimplesnac
            FROM PCPARAMFILIAL
           WHERE NOME = 'MEDUTILIZARSTFONTESIMPLESNAC'
             AND CODFILIAL = '99';
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_medutilizarstfontesimplesnac := 'N';
        END;
        
        -- Se Utilizar, substitui as variáveis para fazer o cálculo
        IF v_medutilizarstfontesimplesnac = 'S' THEN    
          BEGIN
            SELECT NVL(IVAFONTESIMPLESNAC,0)
                 , NVL(ALIQICMS1FONTESIMPLESNAC,0)
                 , NVL(ALIQICMS2FONTESIMPLESNAC,0)
                 , NVL(PAUTAFONTESIMPLESNAC,0)
              INTO Imposto.Tributacao.Iva
                 , Imposto.Tributacao.AliqIcms1
                 , Imposto.Tributacao.AliqIcms2
                 , Imposto.Tributacao.pauta
              FROM PCTRIBUT 
           WHERE (CODST = vnCodSt);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              NULL;
          END;
        END IF; -- Fim-Se Utilizar ST Fonte SIMPLES Nacional
      END IF; -- Fim-se Cliente SIMPLES Nacional    
      --------------------------------------------------------------------   

      -- Pesquisa Dados da PrecificaÃ§Ã£o
      BEGIN
        SELECT PCTABPR.*
          INTO Imposto.Precificacao
          FROM PCTABPR
         WHERE (PCTABPR.CODPROD  = pi_nCodProd)
           AND (PCTABPR.NUMREGIAO = Imposto.Regiao.NumRegiao);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          pio_vOcorreramErros := 'S';
          pio_vMsgErros       := pio_vMsgErros || CHR(13);
          pio_vMsgErros       := pio_vMsgErros || 'Dados nÃ£o encontrados para o Produto: ' || NVL(pi_nCodProd,0) || ' e RegiÃ£o: ' ||  NVL(Imposto.Regiao.NumRegiao,0);
      END;
  
      -- Pesquisa Dados da PCEST
      BEGIN
        SELECT VALORULTENT              
             , VLSTULTENT               
             , VLSTGUIAULTENT           
             , IVAULTENT                
             , ALIQICMS1ULTENT          
             , ALIQICMS2ULTENT          
             , REDBASEIVAULTENT         
             , PERCICMSFRETEFOBSTULTENT 
             , VLFRETECONHECULTENT      
             , PERCALIQEXTGUIAULTENT    
             , BASEICMSULTENT           
             , CUSTONFSEMST             
             , CUSTONFSEMSTGUIAULTENT   
             , PERCMVAORIGULTENT        
          INTO Imposto.Estoque.VALORULTENT              
             , Imposto.Estoque.VLSTULTENT               
             , Imposto.Estoque.VLSTGUIAULTENT           
             , Imposto.Estoque.IVAULTENT                
             , Imposto.Estoque.ALIQICMS1ULTENT          
             , Imposto.Estoque.ALIQICMS2ULTENT          
             , Imposto.Estoque.REDBASEIVAULTENT         
             , Imposto.Estoque.PERCICMSFRETEFOBSTULTENT 
             , Imposto.Estoque.VLFRETECONHECULTENT      
             , Imposto.Estoque.PERCALIQEXTGUIAULTENT    
             , Imposto.Estoque.BASEICMSULTENT           
             , Imposto.Estoque.CUSTONFSEMST             
             , Imposto.Estoque.CUSTONFSEMSTGUIAULTENT   
             , Imposto.Estoque.PERCMVAORIGULTENT             
          FROM PCEST
         WHERE (PCEST.CODFILIAL  = pi_vCodFilial)
           AND (PCEST.CODPROD    = pi_nCodProd);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          pio_vOcorreramErros := 'S';
          pio_vMsgErros       := pio_vMsgErros || CHR(13);
          pio_vMsgErros       := pio_vMsgErros || 'Dados nÃ£o encontrados para o Produto: ' || NVL(pi_nCodProd,0) || ' e Filial: ' ||  NVL(pi_vCodFilial,' ');
      END;
      
    END P_INICIALIZAR_INF_IMPOSTO;
  
   /***************************************
    ***************************************
    ** INICIO DO PROCESSAMENTO PRINCIPAL **
    ***************************************
    ***************************************/
  BEGIN
  
   /*************************************************************************************************
    Inicializa Retornos
    *******************/
    po_vTipoRedSimplesNac          := NULL;
    po_nPercRedSimplesNac          := 0;
    po_nValorRedSimplesNac         := 0;
    po_ValorRedSimplesNacNoPreco   := 0;
    po_ValorRedSimplesNacNoStFonte := 0;
    po_vOcorreramErros             := 'N';
    po_vMsgErros                   := NULL;
    
   /*************************************************************************************************
    MEDICAMENTOS NÃƒO PODEM PARTICIPAR DO SIMPLES NACIONAL
    *****************************************************/
    IF (NVL(pTipoMerc,' ') NOT IN (' ','M','MA')) THEN
    
     /*************************************************************************************************
      Inicializa Record de InformaÃ§Ãµes para CÃ¡lculo do Imposto
      REGRA: ESPECIFICA MEDICAMENTOS
      ********************************************************/
      P_INICIALIZAR_INF_IMPOSTO(pCodCli,
                                pCodProd,
                                psCodFilial,
                                po_vOcorreramErros,
                                po_vMsgErros);
      IF (po_vOcorreramErros = 'S') THEN
        RAISE e_Tratado;
      END IF;                            
    
      -- Se Cliente nÃ£o for Fonte ST Aborta    
      IF (NVL(Imposto.Cliente.CalculaSt,'N') = 'S') AND -- 3826.054937.2015
         (NVL(Imposto.Cliente.ClienteFonteSt,'N') <> 'S') THEN
        po_vOcorreramErros := 'S';
        po_vMsgErros       := po_vMsgErros || CHR(13);
        po_vMsgErros       := po_vMsgErros || 'Cliente: ' || NVL(pCodCli,0) || ' nÃ£o estÃ¡ parametrizado para utilizar ST Fonte';
        RAISE e_Tratado;
      END IF;
    
     /*************************************************************************************************
      CALCULO DO SIMPLES NACIONAL
      REGRA: PACOTE
      ***************************/
    
      --- PERCENTUAL BASE DE REDUÃ‡ÃƒO DE IVA ULT. ENTRADA
      IF NVL(Imposto.Estoque.REDBASEIVAULTENT,0) = 0 THEN
        vnPercentualdeReducaoBaseIVA := 100;
      ELSE
        vnPercentualdeReducaoBaseIVA := Imposto.Estoque.REDBASEIVAULTENT ;
      END IF;
      --- FIM PERCENTUAL BASE DE REDUÃ‡ÃƒO DE ST
    
      --- PERCENTUAL DE REDUÃ‡ÃƒO DO SIMPLES NACIONAL
      IF NVL(Imposto.Tributacao.PercRedPvendaSimplesnac,0) = 0 THEN
        vnPercentualdeRedSimplesNac := 100;
      ELSE
        vnPercentualdeRedSimplesNac := Imposto.Tributacao.PercRedPvendaSimplesnac ;
      END IF;
      --- FIM PERCENTUAL DE REDUÃ‡ÃƒO DO SIMPLES NACIONAL
    
      IF (NVL(Imposto.Cliente.SimplesNacional,'N') = 'S') THEN
        IF (NVL(Imposto.Parametros132.UsaDescSimplesNac,'N') = 'S') THEN
    
           vnVlReducao := pPreco * ( Imposto.Precificacao.PERCDESCSIMPLESNAC / 100);
           
           -- REGRA ESPECIFICA MEDICAMENTOS - CALCULA REDUÃ‡ÃƒO NO PREÃ‡O
           po_vTipoRedSimplesNac := 'P'; 
           --
    
        ELSIF (NVL(Imposto.Parametros132.UsaDescSimplesNac,'N') = 'N') AND
              (NVL(Imposto.Tributacao.PercRedPvendaSimplesnac,0) <> 0) THEN
    
          vnST      := 0;
          vnST_Guia := 0;
    
          -----------------------------------------------------------
          --Autor: Rodrigo Santos
          --SolicitaÃ§Ã£o: HIS.05473.2014
          --Data: 29/12/2014
          --DescriÃ§Ã£o: CÃ¡lculo do simples nacional alterando fator de ajuste.
          -----------------------------------------------------------
          IF (Imposto.Tributacao.AlteraFatorAjusteIVASN = 'S')
            AND (Imposto.Filial.UF = Imposto.Cliente.EstEnt)
          THEN
            vnFatorAjuste := (1 - (Imposto.Estoque.ALIQICMS2ULTENT / 100)) / (1 - (Imposto.Estoque.ALIQICMS1ULTENT / 100));
            vnFatorAjusteGuia := (1 - (Imposto.Estoque.PERCALIQEXTGUIAULTENT / 100)) / (1 - (Imposto.Estoque.ALIQICMS1ULTENT / 100));
    
            IF Imposto.Estoque.PERCMVAORIGULTENT > 0 THEN
              Imposto.Estoque.IVAULTENT := Imposto.Estoque.PERCMVAORIGULTENT;
            END IF;
          ELSE
            vnFatorAjuste := 1;
            vnFatorAjusteGuia := 1;
          END IF;
          -----------------------------------------------------------
    
          IF (Imposto.Tributacao.Iva = 0 ) AND
             (Imposto.Tributacao.pauta = 0 ) AND
             (Imposto.Tributacao.AliqIcms1  <= Imposto.Tributacao.AliqIcms2) THEN
    
             vnVlReducao := 0;
    
             IF (Imposto.Estoque.CUSTONFSEMST > 0) and (Imposto.Estoque.CUSTONFSEMSTGUIAULTENT  > 0) then
    
                vnST1 := (((Imposto.Estoque.CUSTONFSEMST * (1 + ((Imposto.Estoque.IVAULTENT / 100) * (vnPercentualdeRedSimplesNac / 100)))) *
                          (vnPercentualdeReducaoBaseIVA / 100)) * vnFatorAjuste)
                          * (Imposto.Estoque.ALIQICMS1ULTENT / 100);
                vnST2 := Imposto.Estoque.BASEICMSULTENT * (Imposto.Estoque.ALIQICMS2ULTENT / 100);
                vnST := vnST1 - vnST2;
    
                if vnST < 0 then
                  vnST := 0;
                END IF;
    
                vnST1_guia := (((Imposto.Estoque.CUSTONFSEMSTGUIAULTENT  * (1 + ((Imposto.Estoque.IVAULTENT / 100) * (vnPercentualdeRedSimplesNac / 100)))) *
                               (vnPercentualdeReducaoBaseIVA / 100)) * vnFatorAjusteGuia) *
                               (Imposto.Estoque.ALIQICMS1ULTENT / 100);
                vnST2_guia := Imposto.Estoque.VLFRETECONHECULTENT * (Imposto.Estoque.PERCALIQEXTGUIAULTENT / 100);
                vnST_guia := vnST1_guia - vnST2_guia;
    
                if vnST_guia < 0 then
                  vnST_guia := 0;
                END IF;
             END IF;
    
             if (Imposto.Estoque.CUSTONFSEMST = 0) and (Imposto.Estoque.CUSTONFSEMSTGUIAULTENT > 0) then
    
                vnST1_guia := (((Imposto.Estoque.CUSTONFSEMSTGUIAULTENT * (1 + ((Imposto.Estoque.IVAULTENT / 100) *
                               (vnPercentualdeRedSimplesNac / 100)))) *  (vnPercentualdeReducaoBaseIVA / 100)) * vnFatorAjusteGuia) *
                               (Imposto.Estoque.ALIQICMS1ULTENT  / 100);
    
                vnST2_guia := ( Imposto.Estoque.BASEICMSULTENT * (Imposto.Estoque.PERCALIQEXTGUIAULTENT  / 100) +
                   ((Imposto.Estoque.VLFRETECONHECULTENT) * (Imposto.Estoque.PERCICMSFRETEFOBSTULTENT / 100)));
                vnST_guia := vnST1_guia - vnST2_guia;
    
                if vnST_guia < 0 then
                  vnST_guia := 0;
                END IF;
             END IF;
    
             IF (Imposto.Estoque.CUSTONFSEMST > 0) and (Imposto.Estoque.CUSTONFSEMSTGUIAULTENT = 0) THEN
    
                vnST1 := (((Imposto.Estoque.CUSTONFSEMST * (1 + ((Imposto.Estoque.IVAULTENT / 100) *
                          (vnPercentualdeRedSimplesNac / 100)))) * (vnPercentualdeReducaoBaseIVA / 100)) * vnFatorAjuste) *
                          (Imposto.Estoque.ALIQICMS1ULTENT / 100);
                vnST2 := Imposto.Estoque.BASEICMSULTENT * (Imposto.Estoque.ALIQICMS2ULTENT / 100);
                vnST := vnST1 - vnST2;
    
                IF vnST < 0 THEN
                  vnST := 0;
                END IF;
             END IF;
    
             IF (Imposto.Estoque.CUSTONFSEMST = 0) and (Imposto.Estoque.CUSTONFSEMSTGUIAULTENT = 0) THEN
               vnST := 0;
               vnST_guia := 0;
             END IF;
    
             vnVlReducao1 := 0;
             IF (Imposto.Estoque.VLSTULTENT - vnST) >= 0 THEN
               vnVlReducao1 := (Imposto.Estoque.VLSTULTENT - vnST);
             END IF;
    
             vnVlReducao2 := 0;
             IF (Imposto.Estoque.VLSTGUIAULTENT - vnST_guia) >= 0 THEN
               vnVlReducao2 := (Imposto.Estoque.VLSTGUIAULTENT - vnST_guia);
             END IF;
    
             vnVlReducao := vnVlReducao1 + vnVlReducao2;
    
             IF vnVlReducao < 0 THEN
               vnVlReducao := 0;
             END IF;
      
             -- REGRA ESPECIFICA MEDICAMENTOS - CALCULA REDUÃ‡ÃƒO NO PREÃ‡O;
             po_vTipoRedSimplesNac := 'P'; 
             --
    
          ELSE
          
            ------------------------------------------
            -- Procedimento para Calcular o ST Fonte 1
            -- Regra: ESPECIFICA MEDICAMENTOS
            ------------------------------------------
            P_OBTEM_STFONTE_40(psCodFilial,
                               pCodProd,
                               pCodCli,
                               Imposto.Regiao.NumRegiao,
                               pCondVenda,
                               100,
                               Imposto.Tributacao.CodSt,
                               pPreco,
                               pValorIpi,                                
                               pPrecoMaxConsum,
                               Imposto.Estoque.ValorUltEnt,
                               Imposto.Estoque.CustoNfSemSt,
                               pPrecoTabela,
                               'S', -->> Calcula o ST somente com o IVA Fonte
                               'N', -->> NÃ£o Pesquisa Custos
                               'N', -->> NÃ£o Ã© Item Bonificado
                               0,   -->> NÃ£o passa Frete e Outras Despesas
                               vnBaseSt1,
                               vnST1,
                               vvMsgErros_ObtemStFonte,
                               vvRegimeEspIsenStFonte1,
                               vnAliqIcms11,
                               vnAliqIcms21,
                               vnIva1,
                               vnPercBaseRedStFonte1,
                               'O',   -->> Chamada = Outros
                               0,     -->> Não é preciso passar Qtde. para PEPS
                               NULL,  -->> Não é preciso passar Número do Pedido para PEPS
                               pi_vCodFilialNf,
                               vnPautaFonte,
                               vvObservacaoStFonte,
                               vvIndEscalaRelevante,
                               vvCnpjFabricante,
                               vvFabricante,
                               vrDadosFuncep.nVLBASEFCPICMS,
                               vrDadosFuncep.nVLBASEFCPST,
                               vrDadosFuncep.nVLBCFCPSTRET,
                               vrDadosFuncep.nPERFCPSTRET,
                               vrDadosFuncep.nVLFCPSTRET,
                               vrDadosFuncep.nPERFCPSN,
                               vrDadosFuncep.nVLFECP,
                               vrDadosFuncep.nVLACRESCIMOFUNCEP,
                               vrDadosFuncep.nPERACRESCIMOFUNCEP,
                               vrDadosFuncep.nALIQICMSFECP,
                               vrDadosFuncep.nVLCREDFCPICMSSN,
                               vrDadosFuncep.nCODCONFIGFUNCEPMED);
             IF (vvMsgErros_ObtemStFonte IS NOT NULL) THEN
               po_vOcorreramErros := 'S';
               po_vMsgErros       := po_vMsgErros || CHR(13);
               po_vMsgErros       := po_vMsgErros || 'ST 1: ' || vvMsgErros_ObtemStFonte;
               RAISE e_Tratado;
             END IF;                              
    
            ------------------------------------------
            -- Procedimento para Calcular o ST Fonte 2
            -- Regra: ESPECIFICA MEDICAMENTOS
            ------------------------------------------
            P_OBTEM_STFONTE_40(psCodFilial,
                               pCodProd,
                               pCodCli,
                               Imposto.Regiao.NumRegiao,
                               pCondVenda,
                               100,
                               Imposto.Tributacao.CodSt,
                               pPreco,
                               pValorIpi,                                
                               pPrecoMaxConsum,
                               Imposto.Estoque.ValorUltEnt,
                               Imposto.Estoque.CustoNfSemSt,
                               pPrecoTabela,
                               'N', -->> Calcula o ST com o IVA Fonte e ReduÃ§Ã£o Simples Nacional no IVA Fonte
                               'N', -->> NÃ£o Pesquisa Custos
                               'N', -->> NÃ£o Ã© Item Bonificado
                               0,   -->> NÃ£o passa Frete e Outras Despesas
                               vnBaseSt2,
                               vnST2,
                               vvMsgErros_ObtemStFonte,
                               vvRegimeEspIsenStFonte2,
                               vnAliqIcms12,
                               vnAliqIcms22,
                               vnIva2,
                               vnPercBaseRedStFonte2,
                               'O',   -->> Chamada = Outros
                               0,     -->> Não é preciso passar Qtde. para PEPS
                               NULL,  -->> Não é preciso passar Número do Pedido para PEPS
                               pi_vCodFilialNf,
                               vnPautaFonte,
                               vvObservacaoStFonte,
                               vvIndEscalaRelevante,
                               vvCnpjFabricante,
                               vvFabricante,
                               vrDadosFuncep.nVLBASEFCPICMS,
                               vrDadosFuncep.nVLBASEFCPST,
                               vrDadosFuncep.nVLBCFCPSTRET,
                               vrDadosFuncep.nPERFCPSTRET,
                               vrDadosFuncep.nVLFCPSTRET,
                               vrDadosFuncep.nPERFCPSN,
                               vrDadosFuncep.nVLFECP,
                               vrDadosFuncep.nVLACRESCIMOFUNCEP,
                               vrDadosFuncep.nPERACRESCIMOFUNCEP,
                               vrDadosFuncep.nALIQICMSFECP,
                               vrDadosFuncep.nVLCREDFCPICMSSN,
                               vrDadosFuncep.nCODCONFIGFUNCEPMED);
             IF (vvMsgErros_ObtemStFonte IS NOT NULL) THEN
               po_vOcorreramErros := 'S';
               po_vMsgErros       := po_vMsgErros || CHR(13);
               po_vMsgErros       := po_vMsgErros || 'ST 2: ' || vvMsgErros_ObtemStFonte;
               RAISE e_Tratado;
             END IF;                              
    
             -- CÃ¡lculo do Valor da ReduÃ§Ã£o
             -- Regra: PACOTE
             ------------------------------
             vnVlReducao := vnST1 - vnST2;
    
             IF vnVlReducao < 0 THEN
               vnVlReducao := 0;
             END IF;
    
             -- REGRA ESPECIFICA MEDICAMENTOS - CALCULA REDUÃ‡ÃƒO NO ST;
             po_vTipoRedSimplesNac := 'S'; 
             --
    
          END IF;
        END IF; -- Fim UsaDescSimplesNac/PercRedPvendaSimplesnac
      END IF; -- Fim Cliente SimplesNacional
  
      -- CÃ¡lculo do Percentual da ReduÃ§Ã£o
      -- Regra: PACOTE
      -- OBS Medicamentos: Quando a ReduÃ§Ã£o Ã© por Desconto, o % Ã© sobre o PreÃ§o de Tabela
      --                   passado no parÃ¢metro, mas quando Ã© no ST, esse % sobre o PreÃ§o de Venda cujo
      --                   retorno nÃ£o Ã© utilizado em lugar nenhum, se usar informar a quem for usar que Ã© sobre o PreÃ§o de Venda
      ---------------------------------------------------------------------------------------------------------------------------
      IF pPreco <> 0 THEN
        vnPercRedSimplesNasc := ROUND(vnVlReducao / pPreco, 6) * 100;
      END IF;
    
     /*******************************
      Demais Retornos do Procedimento  
      *******************************/
      po_nPercRedSimplesNac  := NVL(vnPercRedSimplesNasc,0);
      po_nValorRedSimplesNac := NVL(vnVlReducao,0);  
      IF    (po_vTipoRedSimplesNac = 'P') THEN
        po_ValorRedSimplesNacNoPreco   := vnVlReducao;
      ELSIF (po_vTipoRedSimplesNac = 'S') THEN
        po_ValorRedSimplesNacNoStFonte := vnVlReducao;
      END IF;    
      
    END IF; -- FIM CONDIÃ‡ÃƒO MEDICAMENTOS NÃƒO PODEM PARTICIPAR DO SIMPLES NACIONAL    
  
  EXCEPTION
    WHEN e_Tratado THEN
      -- Erro Tratado - A Mensagem "po_vMsgErros" jÃ¡ foi gerada anteriormente na origem do Erro
      po_nPercRedSimplesNac  := 0;
      po_nValorRedSimplesNac := 0;  
    WHEN OTHERS THEN
      po_nPercRedSimplesNac  := 0;
      po_nValorRedSimplesNac := 0;  
      po_vOcorreramErros     := 'S';
      po_vMsgErros           := 'Erro Simples Nacional: ' || SUBSTR('Erro: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ' >> ' || SQLERRM,1,200);
  END P_CALC_RED_SIMPLES_NAC;

  /*******************************************************************************
   Nome         : P_OBTEM_CUSTO_PROMO_MARKUP
   Descricão    : Procedimento Obter o Custo da Promoção Markup - DDMEDICA-6900
  **********************************************************************************/                                       
  PROCEDURE P_OBTEM_CUSTO_PROMO_MARKUP(pi_vCodFilial               IN  VARCHAR2,
                                       pi_vCodFilialRetira         IN  VARCHAR2,
                                       pi_nCodProd                 IN  NUMBER,
                                       pi_vOrigemCustoFilialRetira IN  VARCHAR2,
                                       pi_vCustoPromMarkupSt       IN  VARCHAR2,
                                       pi_nNumTransEntCrossDock    IN  NUMBER,
                                       pi_nCustoFinanceiro         IN  NUMBER,
                                       po_vAchouCusto              OUT VARCHAR2,
                                       po_nValorCusto              OUT NUMBER) IS
                         
    vvOpcaoCusto     PCPARAMFILIAL.VALOR%TYPE;                         
    vvCodFilialCusto PCFILIAL.CODIGO%TYPE;
    
  BEGIN
    
    -- Inicializa Retornos
    po_vAchouCusto := 'N';
    po_nValorCusto := 0;
    
    -- Default da Opção de Custo para Custo Financeiro
    vvOpcaoCusto := NVL(pi_vCustoPromMarkupSt,'8');
    
    -- Código da Filial para busca do Custo
    IF (NVL(pi_vOrigemCustoFilialRetira,'V') = 'R') THEN
      vvCodFilialCusto := pi_vCodFilialRetira; 
    ELSE
      vvCodFilialCusto := pi_vCodFilial; 
    END IF;
    
    -- Se Venda Crossdocking o Custo é o da Nota de Entrada
    IF (NVL(pi_nNumTransEntCrossDock,0) > 0) THEN
    
      BEGIN
        SELECT 'S' AS ACHOU
             , PCMOVCOMPLE.CUSTOULTENTCONT 
          INTO po_vAchouCusto
             , po_nValorCusto
          FROM PCMOV
             , PCMOVCOMPLE 
         WHERE (NUMTRANSENT        = pi_nNumTransEntCrossDock)
           AND (PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM) 
           AND (CODPROD            = pi_nCodProd) 
           AND (ROWNUM             = 1);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          po_vAchouCusto := 'N';
          po_nValorCusto := 0;
      END;
    
    -- Se não for Crossdocking o Custo é da PCEST
    ELSE
    
      -- Se já tem o Custo Financeiro evita nova consulta na PCEST
      IF (NVL(pi_nCustoFinanceiro,0) > 0) AND 
         (NVL(vvOpcaoCusto,'8') = '8')    THEN
         
        po_vAchouCusto := 'S';
        po_nValorCusto := pi_nCustoFinanceiro;
      
      ELSE
        
        BEGIN
          SELECT 'S' AS ACHOU
               , CASE 
                   WHEN vvOpcaoCusto = '1'  THEN -- Última entrada
                     CUSTOULTENT
                   WHEN vvOpcaoCusto = '2'  THEN -- Última entrada financeira
                     CUSTOULTENTFIN
                   WHEN vvOpcaoCusto = '3'  THEN -- Custo da NF sem ST
                     CUSTONFSEMST
                   WHEN vvOpcaoCusto = '4'  THEN -- Contábil
                     CUSTOCONT
                   WHEN vvOpcaoCusto = '5'  THEN -- (Real+ICMS)
                     CUSTOREP
                   WHEN vvOpcaoCusto = '6'  THEN -- Custo Real sem ST
                     CUSTOREALSEMST
                   WHEN vvOpcaoCusto = '7'  THEN -- Real
                     CUSTOREAL
                   WHEN vvOpcaoCusto = '8'  THEN -- Financeiro
                     CUSTOFIN
                   WHEN vvOpcaoCusto = '9'  THEN -- Última entrada cont. sem ST
                     VLULTENTCONTSEMST
                   WHEN vvOpcaoCusto = '10' THEN -- Custo Financeiro Sem ST
                     CUSTOFINSEMST
                   WHEN vvOpcaoCusto = '11' THEN -- Custo Ult. Ent. Sem ST 
                     CUSTOULTENTSEMST
                   WHEN vvOpcaoCusto = '12' THEN -- Custo Real Liquido 
                     CUSTOREALLIQ
                   WHEN vvOpcaoCusto = '13' THEN -- Custo Ult. Ent. Líquido
                     CUSTOULTENTLIQ
                   WHEN vvOpcaoCusto = '14' THEN -- Custo Ult. Ent. Fin. Sem ST
                     CUSTOULTENTFINSEMST
                   ELSE                          -- Padrão: Financeiro
                     CUSTOFIN
                 END     
            INTO po_vAchouCusto
               , po_nValorCusto
            FROM PCEST
           WHERE (CODFILIAL = vvCodFilialCusto)
             AND (CODPROD   = pi_nCodProd);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            po_vAchouCusto := 'N';
            po_nValorCusto := 0;
        END;
        
      END IF;
      
      -- Achou Custo Zerado
      IF (po_vAchouCusto = 'S') AND
         (NVL(po_nValorCusto,0) = 0) THEN
        po_vAchouCusto := 'Z';
      END IF; 
      
    END IF;
    
  END P_OBTEM_CUSTO_PROMO_MARKUP;                         

  /*******************************************************************************
   Nome         : P_CALC_DESONERACAO_FATURAMENTO
   Descricão    : Procedimento para Calcular a Desoneração no Faturamento - DDVENDAS-37241
  **********************************************************************************/                                       
  PROCEDURE P_CALC_DESONERACAO_FATURAMENTO(pi_nNumPed        IN NUMBER,
                                           po_vOcorreuErro  OUT VARCHAR2,
                                           po_vMensagemErro OUT VARCHAR) IS

    v_numcasasdecvenda            PCCONSUM.NUMCASASDECVENDA%TYPE;
    v_tipocalcsulframa            PCCONSUM.TIPOCALCSULFRAMA%TYPE;

    vCALCDESONERACAOFATMEDICAM    PCPARAMFILIAL.VALOR%TYPE;
    
    vnVlDescReducaoPis            NUMBER;
    vnPercDescReducaoPisAuxBF     NUMBER;
    vnVlDescReducaoCofins         NUMBER;
    vnPercDescReducaoCofinsAuxBF  NUMBER;
    vnVlDescIcmIsencao            NUMBER;
    vnPercDescIcmIsencao          NUMBER;
    vnVlDescSuframa               NUMBER;
    vnPercDescSuframaAuxBF        NUMBER;
    vnPrecoLiqResultAuxBF         NUMBER;
    vnPrecoTabResultAuxBF         NUMBER;
    vnPrecoRcaResultAuxBF         NUMBER;
    vvErrosBenefFiscais           VARCHAR2(255);
    vvMsgErrosBenefFiscais        VARCHAR2(4000);

    e_Tratado                     EXCEPTION;
    
  BEGIN
  
    po_vOcorreuErro  := 'N';
    po_vMensagemErro := NULL;
  
    BEGIN
      SELECT NVL(NUMCASASDECVENDA,2) NUMCASASDECVENDA
           , TIPOCALCSULFRAMA
        INTO v_numcasasdecvenda
           , v_tipocalcsulframa
        FROM PCCONSUM;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        po_vMensagemErro := 'Não foram encontrados dados na PCCONSUM';
        RAISE e_tratado;
    END;

    PROC_PCPARAMFILIAL('99',
                       'CALCDESONERACAOFATMEDICAM',
                       'N',
                       vCALCDESONERACAOFATMEDICAM);
                       
    IF (vCALCDESONERACAOFATMEDICAM = 'S') THEN                    

      FOR vc_Item IN (SELECT PCPEDC.CODFILIAL
                           , PCPEDC.CODCLI
                           , PCPEDI.CODPROD
                           , PCPEDI.NUMSEQ
                           , PCPEDI.CODST
                           , PCTRIBUT.PERDESCICMISENCAO
                           , PCTRIBUT.APLICADESCISENCAOMED
                           , (PCPEDI.PVENDA 
                              - NVL(PCPEDI.ST,0) 
                              - NVL(PCPEDI.VLREPASSE,0) 
                              - NVL(PCPEDI.VLIPI,0) 
                              - NVL(PCPEDI.VLFECP,0)
                              + NVL(PCPEDI.VLDESCSUFRAMA,0)
                              + NVL(PCPEDI.VLDESCPISSUFRAMA,0)
                              + NVL(PCPEDI.VLDESCREDUCAOPIS,0) 
                              + NVL(PCPEDI.VLDESCREDUCAOCOFINS,0)) BASECALCULO
                           , PCPEDI.QT
                        FROM PCPEDI
                           , PCPEDC
                           , PCTRIBUT
                       WHERE (PCPEDI.NUMPED = PCPEDC.NUMPED)
                         AND (PCPEDI.CODST  = PCTRIBUT.CODST)
                         AND (PCPEDC.NUMPED = pi_nNumPed)) LOOP
                             
        P_OBTER_VALORES_BENEF_FISCAIS(vc_Item.CODFILIAL,
                                      vc_Item.CODFILIAL,
                                      vc_Item.CODCLI,
                                      vc_Item.CODPROD,
                                      vc_Item.CODST,
                                      v_numcasasdecvenda,
                                      v_tipocalcsulframa,
                                      vc_Item.PERDESCICMISENCAO,
                                      vc_Item.APLICADESCISENCAOMED,
                                      ROUND(vc_Item.BASECALCULO,v_numcasasdecvenda), -->> Deve ser usado o Preço com Arredondamento
                                      0, -->> Aqui não irei atualizar o preço de tabela
                                      0, -->> Aqui não irei atualizar o preço base rca
                                      vc_Item.QT,
                                      vnVlDescReducaoPis,
                                      vnPercDescReducaoPisAuxBF,
                                      vnVlDescReducaoCofins,
                                      vnPercDescReducaoCofinsAuxBF,
                                      vnVlDescIcmIsencao,
                                      vnPercDescIcmIsencao,
                                      vnVlDescSuframa,
                                      vnPercDescSuframaAuxBF,
                                      vnPrecoLiqResultAuxBF,
                                      vnPrecoTabResultAuxBF,
                                      vnPrecoRcaResultAuxBF,
                                      vvErrosBenefFiscais,
                                      vvMsgErrosBenefFiscais,
                                      'S'); -- DDVENDAS-37241
        IF (vvErrosBenefFiscais = 'S') THEN
          po_vMensagemErro := vvMsgErrosBenefFiscais;
          RAISE e_tratado;
        END IF;  
        
        UPDATE PCPEDI
           SET PERDESCISENTOICMS = NVL(vnPercDescIcmIsencao,0)
             , VLDESCICMISENCAO  = NVL(vnVlDescIcmIsencao,0)
         WHERE (NUMPED  = pi_nNumPed)
           AND (CODPROD = vc_Item.CODPROD)
           AND (NUMSEQ  = vc_Item.NUMSEQ);
             
      END LOOP;                     
      
    END IF;
    
  EXCEPTION
    WHEN e_Tratado THEN
      po_vOcorreuErro  := 'S';
  END P_CALC_DESONERACAO_FATURAMENTO;                                           

  /*******************************************************************************
   Nome         : P_OBTER_FILIAL_RETIRA_CLIENTE
   Descricão    : Procedimento para Obter a Filial Retira do Cliente
  **********************************************************************************/                                       
  PROCEDURE P_OBTER_FILIAL_RETIRA_CLIENTE(pi_nCodCli            IN  NUMBER,
                                          pi_vCodFilial         IN  VARCHAR2,
                                          pi_nCodFornec         IN  NUMBER,
                                          pi_vUfCliente         IN  VARCHAR2,
                                          po_vAchouFilialRetira OUT VARCHAR2,
                                          po_vCodFilialRetira   OUT VARCHAR) IS
    vvExiste VARCHAR2(1);                                             
  BEGIN

    po_vAchouFilialRetira := 'N';
    po_vCodFilialRetira   := NULL;
    
    BEGIN
      SELECT 'S' ACHOU
           , PCFILIALRETIRAFORNEC.CODFILIALRETIRA
        INTO po_vAchouFilialRetira
           , po_vCodFilialRetira
        FROM PCFILIALRETIRAFORNEC
       WHERE (PCFILIALRETIRAFORNEC.CODFILIAL       = pi_vCodFilial)
         AND (PCFILIALRETIRAFORNEC.CODFORNEC       = pi_nCodFornec)
         AND (PCFILIALRETIRAFORNEC.UFCLIENTE       = pi_vUfCliente)
         AND (PCFILIALRETIRAFORNEC.CODFILIALRETIRA IS NOT NULL);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        po_vAchouFilialRetira := 'N';
    END;
    
    IF (po_vAchouFilialRetira = 'N') THEN
     
      BEGIN
        SELECT 'S' ACHOU
             , PCCLIENTFILIALMED.CODFILIALRETIRA
          INTO po_vAchouFilialRetira
             , po_vCodFilialRetira
          FROM PCCLIENTFILIALMED
         WHERE (PCCLIENTFILIALMED.CODCLI          = pi_nCodCli)
           AND (PCCLIENTFILIALMED.CODFILIAL       = pi_vCodFilial)
           AND (PCCLIENTFILIALMED.CODFILIALRETIRA IS NOT NULL);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          po_vAchouFilialRetira := 'N';
      END;
      
    END IF;
    
    IF (po_vAchouFilialRetira = 'S') AND
       (po_vCodFilialRetira <> pi_vCodFilial) THEN
       
      BEGIN
        SELECT 'S' EXISTE
          INTO vvExiste
          FROM PCFILIALRETIRA
         WHERE (PCFILIALRETIRA.CODFILIALVENDA   = pi_vCodFilial) 
           AND (PCFILIALRETIRA.CODFILIALRETIRA <> '99')
           AND (ROWNUM                          = 1);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vvExiste := 'N';  
      END;
      
      IF (vvExiste = 'S') THEN

        BEGIN
          SELECT 'S' EXISTE
            INTO vvExiste
            FROM PCFILIALRETIRA
           WHERE (PCFILIALRETIRA.CODFILIALVENDA  = pi_vCodFilial) 
             AND (PCFILIALRETIRA.CODFILIALRETIRA = po_vCodFilialRetira);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vvExiste := 'N';  
        END;
        
        IF (vvExiste = 'N') THEN
          po_vAchouFilialRetira := 'N - Filial "' || pi_vCodFilial || '" e Filial Retira "' || po_vCodFilialRetira || '" não existem no cadastro de filiais retira (Rotina 535).';
          po_vCodFilialRetira   := NULL;
        END IF;
        
      END IF;
       
    END IF;     

  END P_OBTER_FILIAL_RETIRA_CLIENTE;                                         
  
  /*******************************************************************************
   Nome         : P_OBTER_FILIAL_RETIRA_CLICOMBO
   Descricão    : Procedimento para Obter a Filial Retira do Cliente num COMBO
  **********************************************************************************/                                       
  PROCEDURE P_OBTER_FILIAL_RETIRA_CLICOMBO(pi_nCodPromocaoMed    IN  NUMBER,
                                           pi_nCodCli            IN  NUMBER,
                                           pi_vCodFilial         IN  VARCHAR2,
                                           pi_vUfCliente         IN  VARCHAR2,
                                           po_vAchouFilialRetira OUT VARCHAR2,
                                           po_vCodFilialRetira   OUT VARCHAR) IS
    vvAchouFilialRetiraFornec VARCHAR2(255); 
    vvCodFilialRetiraFornec   PCFILIALRETIRAFORNEC.CODFILIALRETIRA%TYPE;                                    
  BEGIN

    po_vAchouFilialRetira := 'N';
    po_vCodFilialRetira   := NULL;
    
    FOR vc_FornecedorCombo IN (SELECT DISTINCT PCPRODUT.CODFORNEC
                                 FROM PCDESCONTO
                                    , PCPRODUT
                                WHERE (PCDESCONTO.CODPROD        = PCPRODUT.CODPROD)
                                  AND (PCDESCONTO.CODPROMOCAOMED = pi_nCodPromocaoMed)) LOOP
                                  
      P_OBTER_FILIAL_RETIRA_CLIENTE(pi_nCodCli,
                                    pi_vCodFilial,
                                    vc_FornecedorCombo.CODFORNEC,
                                    pi_vUfCliente,
                                    vvAchouFilialRetiraFornec,
                                    vvCodFilialRetiraFornec);
      
        IF (NVL(po_vCodFilialRetira,vvCodFilialRetiraFornec) <> NVL(vvCodFilialRetiraFornec,'X')) THEN
           po_vAchouFilialRetira := 'N - Filial retira difere entre os fornecedores do combo.';
           po_vCodFilialRetira   := NULL;                 
           EXIT;         
        ELSE 
          IF (vvAchouFilialRetiraFornec = 'S') THEN
             po_vAchouFilialRetira := 'S';
             po_vCodFilialRetira   := vvCodFilialRetiraFornec;
          END IF;
        END IF;
                                        
    END LOOP;                                  
    
  END P_OBTER_FILIAL_RETIRA_CLICOMBO;                                             

END PKG_MEDICAMENTOS;